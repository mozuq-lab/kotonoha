import * as ipaddr from 'ipaddr.js';
import { complete } from './ai';
import { ApiError, errorResponse, validationResponse, type ValidationIssue } from './errors';
import type { ConversionInput, PolitenessLevel } from './prompts';

export interface Env {
  API_KEYS: string;
  WORKERS_AI_API_TOKEN: string;
  WORKERS_AI_ACCOUNT_ID: string;
  WORKERS_AI_GATEWAY_ID: string;
  RATE_LIMITER: RateLimit;
}

const encoder = new TextEncoder();
const origins = new Set(['http://localhost:3000', 'http://localhost:5173']);
const bodyLimit = 64 * 1024;

function configuredKeys(env: Env): string[] {
  const keys = (env.API_KEYS ?? '').split(',').map(key => key.trim()).filter(Boolean);
  if (!keys.length || keys.some(key => !/^[\x20-\x7e]+$/.test(key)) ||
      !/^[\x20-\x7e]+$/.test(env.WORKERS_AI_API_TOKEN ?? '') ||
      !/^[a-fA-F0-9]{32}$/.test(env.WORKERS_AI_ACCOUNT_ID ?? '') ||
      !/^[\x20-\x7e]+$/.test(env.WORKERS_AI_GATEWAY_ID ?? '') || !env.RATE_LIMITER) {
    throw new ApiError('CONFIG_INVALID');
  }
  return keys;
}

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
      catch (error) { response = errorResponse(error); }
    }
    if (origin) {
      response.headers.set('Access-Control-Allow-Credentials', 'true');
      response.headers.set('Vary', 'Origin');
      if (allowed) response.headers.set('Access-Control-Allow-Origin', origin);
    }
    return response;
  },
} satisfies ExportedHandler<Env>;
