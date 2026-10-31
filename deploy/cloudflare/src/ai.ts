import type { Env } from './api';
import { ApiError } from './errors';
import { makePrompt, type ConversionInput } from './prompts';

type Completion = { choices?: { message?: { content?: unknown }; finish_reason?: string }[] };

export async function complete(input: ConversionInput, env: Env): Promise<string> {
  // 意味が反転した実例がある答えの語は、従来どおり AI へ送らない。
  const word = input.input_text.replace(/[。．.！!]+$/u, '');
  if (['はい', 'いいえ', 'うん', 'ううん'].includes(word)) return `${word}。`;

  const deadline = AbortSignal.timeout(10000);
  const payload = JSON.stringify(makePrompt(input));
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
        }, body: payload },
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
      return text;
    } catch (error) {
      failure = signal.aborted ? new ApiError('AI_API_TIMEOUT')
        : error instanceof ApiError ? error
          : new ApiError('AI_API_ERROR', true, error instanceof Error ? error.name : typeof error);
    }
    if (!failure.retryable || attempt === 1) throw failure;
    await new Promise<void>(resolve => setTimeout(resolve, 500));
    if (deadline.aborted) throw new ApiError('AI_API_TIMEOUT');
  }
  throw new ApiError('AI_API_ERROR');
}
