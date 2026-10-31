/** 丁寧さの段階。アプリが送る値と同じ。 */
export type PolitenessLevel = 'casual' | 'normal' | 'polite';
/** 検証済みの変換の入力。 */
export interface ConversionInput {
  /** 利用者が入力した文。 */
  input_text: string;
  /** 選んだ丁寧さ。 */
  politeness_level: PolitenessLevel;
  /** 再生成のときだけある、前回の変換結果。 */
  previous_result?: string;
}

// 既存の意味を守る指示をそのまま移植する。
const system = "あなたは、発話が難しい人（本人）が文字盤で打った短い言葉を、本人に代わって相手（家族・介護者・医療者など）に伝える文に整えます。入力は、ひらがなや単語を並べただけのことがあります。次を必ず守ってください。\n- 本人が相手に言う文として書く。相手の様子を尋ねる文や、相手を主語にした文に変えない。\n- 意味を変えない。否定（〜ない・〜ないで）、過去か未来か、数・時刻、名前、左右、体の部位は入力のとおりに残す。\n- 入力に無い内容を足さない。丁寧さのための言い回しは足してよいが、理由や気持ちや状況は足さない。\n- 単語だけの入力に、したいこと（行きたい・食べたい・欲しいなど）を推測で足さない。その語を残した短い文にする（例: 「トイレ」は「トイレです」。「トイレに行きたいです」にはしない）。\n- お願い・訴え・質問・報告の区別を変えない。\n- 自分の動作に尊敬語を使わない。自分の動作には謙譲語か丁寧語、相手の動作には尊敬語を使う。\n- ひらがなの語が複数の意味に読めるときは、体の症状や訴え、お願いとしての読みを優先する（例: 「はきそう」は「吐きそう」）。\n- 変換後の文を1つだけ出力する。説明、かぎかっこ、記号、候補の列挙は付けない。";
const instructions: Record<PolitenessLevel, string> = {
  "casual": "家族や親しい人に話すような、くだけた言い方にしてください。",
  "normal": "「です・ます」の、標準的な丁寧さにしてください。",
  "polite": "目上の人や初対面の人に話すような、丁寧な敬語にしてください。「〜いただけますか」「〜しております」など、「です・ます」より一段丁寧な言い方を使います。大げさな言い回しは避けます。形容詞は「痛うございます」「寒うございます」のような古い言い方にしません。"
};

/**
 * Workers AI へ送る本文を作る。
 *
 * 再生成は前回と違う言い回しを出しやすいように `temperature` を上げる。
 *
 * @param input 検証済みの入力
 * @param keepNegation 前の出力で否定が消えたとき true。同じ本文の再送では同じ誤りが起きやすい
 * @returns OpenAI 互換 API の本文
 */
export function makePrompt(input: ConversionInput, keepNegation = false) {
  let user = `${instructions[input.politeness_level]}\n\n入力: ${input.input_text}`;
  if (input.previous_result !== undefined) {
    user += `\n前回の結果: ${input.previous_result}\n\n前回とは違う言い回しにしてください。前回と同じ文は出さず、意味は変えません。`;
  }
  if (keepNegation) user += '\n\n入力の否定は必ず残してください。';
  return {
    model: '@cf/google/gemma-4-26b-a4b-it',
    messages: [{ role: 'system', content: system }, { role: 'user', content: user }],
    max_tokens: 256,
    temperature: input.previous_result === undefined ? 0.7 : 0.9,
    chat_template_kwargs: { enable_thinking: false },
  };
}
