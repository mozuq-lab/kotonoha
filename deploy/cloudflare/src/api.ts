import * as ipaddr from 'ipaddr.js';
import { complete } from './ai';
import { ApiError, errorResponse, logFailure, validationResponse, type ValidationIssue } from './errors';
import type { ConversionInput, PolitenessLevel } from './prompts';

/** Worker へ渡る設定。秘密は `wrangler secret put` で入れ、`RATE_LIMITER` は wrangler.jsonc で定義する。 */
export interface Env {
  /** 端末キー。カンマ区切りで新旧のキーを併用できる。 */
  API_KEYS: string;
  /** Workers AI を呼べる API トークン。 */
  WORKERS_AI_API_TOKEN: string;
  /** Cloudflare のアカウント ID（32 桁の 16 進数）。 */
  WORKERS_AI_ACCOUNT_ID: string;
  /** 通す AI Gateway の ID。全体の回数と支出の制限はここで効く。 */
  WORKERS_AI_GATEWAY_ID: string;
  /** 送信元ごとの標準レート制限。拠点ごとの概算（ADR-002）。 */
  RATE_LIMITER: RateLimit;
}

const encoder = new TextEncoder();
/** CORS の許可元。手元の Flutter Web の確認用だけを許す。 */
const origins = new Set(['http://localhost:3000', 'http://localhost:5173']);
/** 受け取る本文の上限（バイト）。 */
const bodyLimit = 64 * 1024;

/**
 * 設定を確かめ、端末キーの一覧を返す。
 *
 * Worker には起動時の検査が無いので、リクエストごとに確かめる。
 *
 * @returns 空白を除いた端末キー
 * @throws {ApiError} 設定の不足・不正のとき `AI_PROVIDER_ERROR`
 */
function configuredKeys(env: Env): string[] {
  const keys = (env.API_KEYS ?? '').split(',').map(key => key.trim()).filter(Boolean);
  if (!keys.length || keys.some(key => !/^[\x20-\x7e]+$/.test(key)) ||
      !/^[\x20-\x7e]+$/.test(env.WORKERS_AI_API_TOKEN ?? '') ||
      !/^[a-fA-F0-9]{32}$/.test(env.WORKERS_AI_ACCOUNT_ID ?? '') ||
      !/^[\x20-\x7e]+$/.test(env.WORKERS_AI_GATEWAY_ID ?? '') || !env.RATE_LIMITER) {
    throw new ApiError('AI_PROVIDER_ERROR', false, 'invalid_config');
  }
  return keys;
}

/**
 * `X-API-Key` が端末キーのどれかと一致するかを、時間差から推測されない形で確かめる。
 *
 * 長さをそろえるために SHA-256 で比べ、一致しても途中で抜けずに全部のキーと比べる。
 *
 * @returns 一致したら true
 */
async function authenticated(request: Request, keys: string[]): Promise<boolean> {
  const supplied = request.headers.get('X-API-Key');
  if (!supplied || !/^[\x20-\x7e]+$/.test(supplied)) return false;
  const digest = (value: string) => crypto.subtle.digest('SHA-256', encoder.encode(value));
  const candidate = await digest(supplied);
  let accepted = false;
  for (const key of keys) {
    const same = crypto.subtle.timingSafeEqual(candidate, await digest(key));
    accepted = same || accepted;
  }
  return accepted;
}

/**
 * 本文を上限まで読む。
 *
 * `Content-Length` は無いことも偽られることもあるので、宣言を見たうえで実際のバイト数も数える。
 *
 * @returns UTF-8 として解釈した本文。本文が無ければ空文字
 * @throws {ApiError} 上限を超えたとき `PAYLOAD_TOO_LARGE`
 */
async function readBody(request: Request): Promise<string> {
  const declared = request.headers.get('Content-Length');
  if (declared && /^\d+$/.test(declared) && Number(declared) > bodyLimit) {
    throw new ApiError('PAYLOAD_TOO_LARGE');
  }
  const reader = request.body?.getReader();
  if (!reader) return '';
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > bodyLimit) {
        void reader.cancel().catch(() => {});
        throw new ApiError('PAYLOAD_TOO_LARGE');
      }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  return new TextDecoder().decode(bytes);
}

/**
 * 本文を検証し、AI へ渡す入力にする。
 *
 * 文字列は前後の空白を除き、文字数はコードポイントで数える（絵文字を 1 文字にする）。
 *
 * @param value JSON として解釈した本文
 * @param regenerating 再生成なら true。`previous_result` を必須にする
 * @returns 正しければ入力、誤りがあれば問題の一覧
 */
function validate(value: unknown, regenerating: boolean): ConversionInput | ValidationIssue[] {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    return [{ type: 'model_attributes_type', loc: ['body'], msg: '入力が不正です' }];
  }
  const body = value as Record<string, unknown>;
  const issues: ValidationIssue[] = [];
  function text(field: string, min: number, max: number): string {
    if (!(field in body)) {
      issues.push({ type: 'missing', loc: ['body', field], msg: '必須項目がありません' });
      return '';
    }
    const result = typeof body[field] === 'string' ? body[field].trim() : '';
    const length = [...result].length;
    if (length < min || length > max) {
      issues.push({ type: 'value_error', loc: ['body', field], msg: '入力が不正です' });
    }
    return result;
  }
  const input_text = text('input_text', 2, 500);
  const level = body.politeness_level;
  if (!('politeness_level' in body)) {
    issues.push({ type: 'missing', loc: ['body', 'politeness_level'], msg: '必須項目がありません' });
  } else if (!['casual', 'normal', 'polite'].includes(level as string)) {
    issues.push({ type: 'enum', loc: ['body', 'politeness_level'], msg: '許可されていない値です' });
  }
  const previous_result = regenerating ? text('previous_result', 1, 1000) : undefined;
  return issues.length ? issues : { input_text, politeness_level: level as PolitenessLevel,
    ...(regenerating ? { previous_result } : {}) };
}

/**
 * レート制限の識別子を作る。
 *
 * API・送信元・UTC の分を HMAC にまとめ、生の IP を制限機能へ渡さない。分が変わると別の識別子になるので、
 * 1 分をまたいで同じ送信元を結び付けられない。IPv4 射影は IPv4 に、IPv6 は /64 にそろえる。
 *
 * @param route API のパス。変換と再生成で枠を分ける
 * @returns 16 進数の識別子
 */
async function rateKey(request: Request, route: string, env: Env): Promise<string> {
  let source = 'unknown';
  try {
    const address = ipaddr.process(request.headers.get('CF-Connecting-IP') ?? '');
    source = address.kind() === 'ipv6'
      ? ipaddr.IPv6.networkAddressFromCIDR(`${address}/64`).toString() : address.toString();
  } catch { /* 信頼する送信元が無ければ同じ枠。不正な XFF へフォールバックしない。 */ }
  const key = await crypto.subtle.importKey('raw', encoder.encode(env.API_KEYS),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const value = encoder.encode(`${route}|${source}|${Math.floor(Date.now() / 60000)}`);
  const signature = new Uint8Array(await crypto.subtle.sign('HMAC', key, value));
  return Array.from(signature, byte => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * パスと順序を決める本体。
 *
 * 順序は認証 → 本文の上限 → 検証 → レート制限 → 変換。無認証では本文を読まない。
 *
 * @throws {ApiError} 利用者へ返す失敗。`fetch` の側で応答に変える
 */
async function route(request: Request, env: Env): Promise<Response> {
  const path = new URL(request.url).pathname;
  if (!['/api/v1/health', '/api/v1/ai/convert', '/api/v1/ai/regenerate'].includes(path)) {
    return Response.json({ detail: 'Not Found' }, { status: 404 });
  }
  const keys = configuredKeys(env);
  if (path === '/api/v1/health') {
    if (request.method !== 'GET') return Response.json({ detail: 'Method Not Allowed' },
      { status: 405, headers: { Allow: 'GET' } });
    return Response.json({ status: 'ok', ai_provider: 'workers_ai', version: '1.0.0',
      timestamp: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z') });
  }
  if (request.method !== 'POST') return Response.json({ detail: 'Method Not Allowed' },
    { status: 405, headers: { Allow: 'POST' } });
  if (!await authenticated(request, keys)) return Response.json(
    { detail: 'Invalid or missing API key.' }, { status: 401, headers: { 'WWW-Authenticate': 'X-API-Key' } });
  const raw = await readBody(request);
  let body: unknown;
  try { body = JSON.parse(raw); }
  catch { return validationResponse([{ type: 'json_invalid', loc: ['body'],
    msg: 'JSON として解釈できません' }]); }
  const input = validate(body, path.endsWith('/regenerate'));
  if (Array.isArray(input)) return validationResponse(input);
  if (!(await env.RATE_LIMITER.limit({ key: await rateKey(request, path, env) })).success) {
    throw new ApiError('RATE_LIMIT_EXCEEDED');
  }
  const started = performance.now();
  const converted_text = await complete(input, env);
  return Response.json({ converted_text, original_text: input.input_text,
    politeness_level: input.politeness_level, processing_time_ms: Math.floor(performance.now() - started) });
}

export default {
  /** リクエストの入口。例外をここで応答に変え、CORS のヘッダーをそろえる。 */
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get('Origin');
    const allowed = origin !== null && origins.has(origin);
    let response: Response;
    if (request.method === 'OPTIONS' && request.headers.has('Access-Control-Request-Method')) {
      response = new Response(allowed ? 'OK' : 'Disallowed CORS origin', { status: allowed ? 200 : 400,
        headers: { 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, X-API-Key', 'Access-Control-Max-Age': '600' } });
    } else {
      try { response = await route(request, env); }
      catch (error) { logFailure(error); response = errorResponse(error); }
    }
    if (origin) {
      response.headers.set('Access-Control-Allow-Credentials', 'true');
      response.headers.set('Vary', 'Origin');
      if (allowed) response.headers.set('Access-Control-Allow-Origin', origin);
    }
    return response;
  },
} satisfies ExportedHandler<Env>;
