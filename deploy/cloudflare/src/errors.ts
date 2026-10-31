const errors = {
  PAYLOAD_TOO_LARGE: [413, '送る内容が大きすぎます。'],
  RATE_LIMIT_EXCEEDED: [429, 'リクエスト数が上限に達しました。しばらく待ってから再試行してください。'],
  AI_PROVIDER_ERROR: [503, 'AI変換サービスが一時的に利用できません。しばらく待ってから再度お試しください。'],
  AI_API_TIMEOUT: [504, 'AI変換APIがタイムアウトしました。しばらく待ってから再度お試しください。'],
  AI_RATE_LIMIT: [429, 'いまAI変換を使えません。混み合っているか、利用の上限に達しています。時間をおいて試すか、元の文をお使いください。'],
  AI_API_ERROR: [500, 'AI変換APIからのレスポンスに失敗しました。しばらく待ってから再度お試しください。'],
  INTERNAL_ERROR: [500, '予期しないエラーが発生しました。'],
} as const;

export class ApiError extends Error {
  constructor(readonly code: keyof typeof errors, readonly retryable = false,
    readonly detail?: string) { super(code); }
}

// 障害の原因を wrangler tail で追うための最小限。入力・IP・例外の文言は載せない。
export function logFailure(error: unknown): void {
  const known = error instanceof ApiError;
  console.error(JSON.stringify({ event: 'request_failed',
    code: known ? error.code : 'INTERNAL_ERROR',
    cause: known ? error.detail : error instanceof Error ? error.name : typeof error }));
}

export function errorResponse(error: unknown): Response {
  const code = error instanceof ApiError ? error.code : 'INTERNAL_ERROR';
  const [status, message] = errors[code];
  const limited = code === 'RATE_LIMIT_EXCEEDED';
  return Response.json({ success: false, data: null, error: {
    code, message, status_code: status, ...(limited ? { retry_after: 60 } : {}),
  } }, { status, headers: limited ? {
    'Retry-After': '60', 'X-RateLimit-Limit': '12',
    'X-RateLimit-Remaining': '0', 'X-RateLimit-Reset': '60',
  } : {} });
}

export type ValidationIssue = {
  type: 'missing' | 'value_error' | 'enum' | 'json_invalid' | 'model_attributes_type';
  loc: (string | number)[];
  msg: '必須項目がありません' | '入力が不正です' | '許可されていない値です' | 'JSON として解釈できません';
};

export function validationResponse(detail: ValidationIssue[]): Response {
  return Response.json({ error: '入力データが不正です', detail, error_code: 'VALIDATION_ERROR' },
    { status: 422 });
}
