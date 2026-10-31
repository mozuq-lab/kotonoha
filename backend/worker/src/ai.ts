import type { Env } from './api';
import { ApiError } from './errors';
import { makePrompt, type ConversionInput } from './prompts';

/** Workers AI の応答のうち使う部分。上流の値なので、どの項目も無い場合を考える。 */
type Completion = { choices?: { message?: { content?: unknown }; finish_reason?: string }[] };

/**
 * 否定に見えるが否定ではない語。
 *
 * 語の切れ目が無い入力では「はないたい」と「うごかないたすけて」を文字列で区別できない。ここに無いものは
 * 否定として扱い、迷ったら止める側に倒す（止めても元の文は使える）。
 */
const notNegation = /はないた|あんない|ないかに|ないしょ|すみません|ませんか/gu;
/** 入力の否定。「なくなった」は語そのものの場合があるので、前に文字があるときだけ数える。 */
const negatedInput = /ない|なかっ|なくて|なく$|.なくな|ません/u;
/** 出力の否定に見えるが、否定ではない言い方。 */
const notOutputNegation = /すみません|ませんか/gu;
/**
 * 出力に残った否定。「おなか」に当たらないよう「なか」だけでは数えない。
 *
 * 「汚」「幼」は「きたない」「おさない」の変換先で、ここに無いと正しい変換を止める。
 */
const negatedOutput = /ない|なく|なかっ|ません|かねます|無い|不要|汚|幼/u;

/**
 * 入力の否定が出力に残っているかを確かめる。
 *
 * モデルは「いたくない」を「痛いです」にすることがあり（2026-10-31 に本番で 5 回中 3 回）、
 * 利用者は発話で訂正できない。否定を足す向きは「いただけませんか」と区別できないので見ない。
 *
 * @param input 入力した文
 * @param output モデルの出力
 * @returns 入力に否定が無い、または出力に否定が残っていれば true
 */
function keepsNegation(input: string, output: string): boolean {
  return !negatedInput.test(input.replace(notNegation, ''))
    || negatedOutput.test(output.replace(notOutputNegation, ''));
}

/**
 * 入力を Workers AI で変換する。
 *
 * 1 回 8 秒・全体 10 秒で打ち切る。通信の失敗、429、否定が消えた出力だけ 1 度再試行する。途中で切れた
 * 出力と否定が消えた出力は、本人が言っていない文を伝えないように返さない。
 *
 * @param input 検証済みの入力
 * @param env 接続先と秘密
 * @returns 変換後の文
 * @throws {ApiError} 変換できなかったとき
 */
export async function complete(input: ConversionInput, env: Env): Promise<string> {
  // 意味が反転した実例がある答えの語は、従来どおり AI へ送らない。
  const word = input.input_text.replace(/[。．.！!]+$/u, '');
  if (['はい', 'いいえ', 'うん', 'ううん'].includes(word)) return `${word}。`;

  const deadline = AbortSignal.timeout(10000);
  let negationLost = false;
  for (let attempt = 0; attempt < 2; attempt++) {
    const signal = AbortSignal.any([deadline, AbortSignal.timeout(8000)]);
    let failure: ApiError;
    try {
      const response = await fetch(
        `https://api.cloudflare.com/client/v4/accounts/${env.WORKERS_AI_ACCOUNT_ID}/ai/v1/chat/completions`,
        { method: 'POST', signal, redirect: 'manual', headers: {
          Authorization: `Bearer ${env.WORKERS_AI_API_TOKEN}`, 'Content-Type': 'application/json',
          'cf-aig-gateway-id': env.WORKERS_AI_GATEWAY_ID,
          'cf-aig-collect-log': 'false', 'cf-aig-skip-cache': 'true',
        }, body: JSON.stringify(makePrompt(input, negationLost)) },
      );
      if (!response.ok) {
        void response.body?.cancel();
        throw new ApiError(response.status === 429 ? 'AI_RATE_LIMIT' : 'AI_API_ERROR',
          response.status === 429, `http_${response.status}`);
      }
      let result: Completion;
      try { result = await response.json<Completion>(); }
      catch (error) {
        if (error instanceof SyntaxError) throw new ApiError('AI_API_ERROR', false, 'SyntaxError');
        throw error; // 本文の受信中の切断も、外側の通信失敗の再試行へ渡す。
      }
      const choice = result?.choices?.[0];
      const text = typeof choice?.message?.content === 'string' ? choice.message.content.trim() : '';
      if (!text || choice?.finish_reason === 'length') {
        throw new ApiError('AI_API_ERROR', false, 'unusable_completion');
      }
      if (!keepsNegation(input.input_text, text)) {
        throw new ApiError('AI_MEANING_CHANGED', true, 'negation_lost');
      }
      return text;
    } catch (error) {
      failure = signal.aborted ? new ApiError('AI_API_TIMEOUT')
        : error instanceof ApiError ? error
          : new ApiError('AI_API_ERROR', true, error instanceof Error ? error.name : typeof error);
    }
    if (!failure.retryable || attempt === 1) throw failure;
    negationLost = failure.code === 'AI_MEANING_CHANGED';
    await new Promise<void>(resolve => setTimeout(resolve, 500));
    if (deadline.aborted) throw new ApiError('AI_API_TIMEOUT');
  }
  throw new ApiError('AI_API_ERROR');
}
