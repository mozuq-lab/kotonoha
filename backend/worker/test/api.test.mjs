import assert from 'node:assert/strict';
import { request as httpRequest } from 'node:http';
import { after, afterEach, before, test } from 'node:test';
import { build } from 'esbuild';
import { unstable_readConfig } from 'wrangler';
import { Log, LogLevel, Miniflare, convertV4MiniflareOptions } from 'miniflare';

const account = '0'.repeat(32);
const upstreamPath = `/client/v4/accounts/${account}/ai/v1/chat/completions`;
const convert = '/api/v1/ai/convert';
const regenerate = '/api/v1/ai/regenerate';
const input = { input_text: '水 ぬるく', politeness_level: 'normal' };
const bindings = {
  API_KEYS: 'contract-key-A,contract-key-B',
  WORKERS_AI_API_TOKEN: 'upstream-token',
  WORKERS_AI_ACCOUNT_ID: account,
  WORKERS_AI_GATEWAY_ID: 'kotonoha-test',
};
let worker;
let workerOptions;
const pending = [];
let source = 0;
let logs = '';

before(async () => {
  const config = unstable_readConfig({ config: 'wrangler.jsonc' }, { hideWarnings: true });
  const bundle = await build({ entryPoints: ['src/index.ts'], bundle: true, write: false,
    format: 'esm', external: ['cloudflare:workers'], target: 'es2022' });
  workerOptions = overrides => convertV4MiniflareOptions({
    modules: true, script: bundle.outputFiles[0].text, compatibilityDate: config.compatibility_date,
    bindings: { ...bindings, ...overrides }, log: new Log(LogLevel.ERROR),
    outboundService: { node(request, response) {
      assert.equal(request.url, upstreamPath);
      assert.equal(request.method, 'POST');
      assert.equal(request.headers.host, 'api.cloudflare.com');
      let body = '';
      request.on('data', chunk => { body += chunk; });
      request.on('end', () => {
        const reply = pending.shift();
        assert.ok(reply, 'unexpected upstream request');
        reply.inspect?.({ body, headers: request.headers });
        if (reply.error) { request.socket.destroy(); return; }
        if (reply.partial) {
          response.writeHead(200, { 'content-type': 'application/json' });
          response.write('{"choices":[');
          setTimeout(() => response.destroy(), 20);
          return;
        }
        const send = () => {
          response.writeHead(reply.status, { 'content-type': 'application/json' });
          response.end(reply.raw ?? JSON.stringify(reply.body));
        };
        if (reply.delay) setTimeout(send, reply.delay); else send();
      });
    } },
    ratelimits: Object.fromEntries(config.ratelimits.map(({ name, ...value }) => [name, value])),
    handleStructuredLogs(event) { logs += JSON.stringify(event); },
  });
  worker = new Miniflare(workerOptions());
  await worker.ready;
});
after(async () => { await worker?.dispose(); });
afterEach(() => {
  const remaining = pending.splice(0);
  assert.equal(remaining.length, 0, 'expected upstream request was not made');
});

function completion(text = 'お水をぬるめでお願いします', finish = 'stop') {
  return { choices: [{ message: { content: text }, finish_reason: finish }] };
}
function provider(body = completion(), status = 200, inspect) {
  const reply = { body, status, inspect };
  pending.push(reply);
  return {
    times(count) { for (let i = 1; i < count; i++) pending.push({ ...reply }); },
    delay(milliseconds) { reply.delay = milliseconds; },
  };
}
function post(body = input, { path = convert, ip, headers = {}, key = 'contract-key-A' } = {}) {
  const sender = ip ?? `192.0.${Math.floor(++source / 250)}.${source % 250 + 1}`;
  return worker.dispatchFetch(`http://localhost${path}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'X-API-Key': key,
      'CF-Connecting-IP': sender, ...headers },
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });
}

// 識別子は UTC の分で切り替わる。連続の途中で分をまたぐと 429 にならないので、境目を避けて始める。
async function awayFromMinuteBoundary() {
  const left = 60000 - Date.now() % 60000;
  if (left < 5000) await new Promise(resolve => setTimeout(resolve, left + 50));
}

test('health is a real unauthenticated HTTP response', async () => {
  const response = await worker.dispatchFetch('http://localhost/api/v1/health');
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.status, 'ok');
  assert.equal(body.ai_provider, 'workers_ai');
  assert.equal(body.version, '1.0.0');
  assert.match(body.timestamp, /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/);
});

// 本文を送信し終える前に応答が来ることを実 socket で見る。全部読んでから断る実装は赤になる。
async function unfinishedRequest(headers, firstChunk) {
  const url = new URL(convert, await worker.ready);
  return new Promise((resolve, reject) => {
    const request = httpRequest(url, { method: 'POST', headers }, response => {
      resolve(response.statusCode);
      response.resume();
      request.destroy();
    });
    request.on('error', reject);
    request.setTimeout(2000, () => request.destroy(new Error('server waited for the whole body')));
    request.flushHeaders();
    if (firstChunk) request.write(firstChunk);
  });
}
test('unauthenticated HTTP upload is rejected before the client sends its body', async () => {
  assert.equal(await unfinishedRequest({ 'X-API-Key': 'bad', 'Content-Length': '1048576' }), 401);
});
test('declared oversized HTTP upload is rejected without receiving its body', async () => {
  assert.equal(await unfinishedRequest({ 'X-API-Key': 'contract-key-A', 'Content-Length': '65537' }), 413);
});
test('chunked HTTP upload is stopped once its bytes exceed the limit, before upload completes', async () => {
  assert.equal(await unfinishedRequest({ 'X-API-Key': 'contract-key-A', 'Transfer-Encoding': 'chunked' },
    '0'.repeat(65537)), 413);
});

for (const path of [convert, regenerate]) {
  // 本文を読まずに断ることは上の実 socket の試験で見る。大きな本文は書き込みの途中で切られ、クライアントが落ちる。
  test(`${path}: authentication precedes parsing of an invalid body`, async () => {
    const response = await post('CANARY-PRIVATE', { path, key: 'bad',
      headers: { Origin: 'http://localhost:3000' } });
    assert.equal(response.status, 401);
    assert.equal(response.headers.get('www-authenticate'), 'X-API-Key');
    assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:3000');
    assert.deepEqual(await response.json(), { detail: 'Invalid or missing API key.' });
  });
  test(`${path}: authenticated oversized streamed body is 413`, async () => {
    const response = await post('0'.repeat(65537), { path });
    assert.equal(response.status, 413);
    assert.equal((await response.json()).error.code, 'PAYLOAD_TOO_LARGE');
  });
}

for (const key of ['contract-key-A', 'contract-key-B']) {
  test(`accepts configured key ${key} and preserves the flat conversion contract`, async () => {
    provider();
    const response = await post({ ...input, input_text: '  水 ぬるく  ' }, { key });
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.deepEqual(Object.keys(body).sort(),
      ['converted_text', 'original_text', 'politeness_level', 'processing_time_ms']);
    assert.equal(body.converted_text, 'お水をぬるめでお願いします');
    assert.equal(body.original_text, '水 ぬるく');
    assert.equal(body.politeness_level, 'normal');
    assert.ok(Number.isInteger(body.processing_time_ms) && body.processing_time_ms >= 0);
    assert.equal(response.headers.get('x-ratelimit-limit'), null);
  });
}

for (const body of [
  {}, { ...input, input_text: '' }, { ...input, input_text: 'あ' },
  { ...input, input_text: 'あ'.repeat(501) }, { ...input, input_text: null },
  { ...input, politeness_level: 'very_polite' }, { ...input, politeness_level: null },
  '{not JSON', [],
]) {
  test(`invalid request is a sanitized 422: ${JSON.stringify(body).slice(0, 80)}`, async () => {
    const response = await post(body);
    assert.equal(response.status, 422);
    const error = await response.json();
    assert.equal(error.error_code, 'VALIDATION_ERROR');
    assert.equal(typeof error.error, 'string');
    assert.ok(error.detail.length > 0);
    assert.deepEqual(Object.keys(error.detail[0]).sort(), ['loc', 'msg', 'type']);
  });
}

test('exactly 64 KiB is parsed; bytes beyond the limit are rejected', async () => {
  assert.equal((await post('x'.repeat(65536))).status, 422);
});
test('Unicode limits count code points, accepting the largest legitimate regeneration', async () => {
  provider();
  const response = await post({ input_text: '😀'.repeat(500), politeness_level: 'polite',
    previous_result: '😀'.repeat(1000) }, { path: regenerate });
  assert.equal(response.status, 200);
});
for (const previous_result of ['', ' ', 'あ'.repeat(1001)]) {
  test(`rejects invalid previous_result length ${previous_result.length}`, async () => {
    assert.equal((await post({ ...input, previous_result }, { path: regenerate })).status, 422);
  });
}

test('regeneration sends the original prompt and previous result only to the configured AI API', async () => {
  let sent;
  let sentHeaders;
  provider(completion('お水をぬるめにしてください'), 200, options => {
    sent = JSON.parse(options.body); sentHeaders = new Headers(options.headers);
  });
  const response = await post({ ...input, previous_result: '前回の文-CANARY-PRIVATE' },
    { path: regenerate, ip: '198.51.100.27' });
  assert.equal(response.status, 200);
  assert.equal(sent.model, '@cf/google/gemma-4-26b-a4b-it');
  assert.equal(sent.max_tokens, 256);
  assert.equal(sent.temperature, 0.9);
  assert.deepEqual(sent.chat_template_kwargs, { enable_thinking: false });
  assert.match(sent.messages[0].content, /入力に無い内容を足さない/);
  assert.match(sent.messages[0].content, /否定/);
  assert.match(sent.messages[1].content, /前回の結果: 前回の文-CANARY-PRIVATE/);
  assert.equal(sentHeaders.get('cf-aig-gateway-id'), 'kotonoha-test');
  assert.equal(sentHeaders.get('cf-aig-collect-log'), 'false');
  assert.equal(sentHeaders.get('cf-aig-skip-cache'), 'true');
  for (const value of ['198.51.100.27', 'contract-key-A', 'cf-connecting-ip', 'x-forwarded-for']) {
    assert.ok(!JSON.stringify(sent).includes(value));
    assert.ok(!JSON.stringify([...sentHeaders]).includes(value));
  }
});

for (const [input_text, expected] of [['はい', 'はい。'], ['いいえ！', 'いいえ。'], ['うん', 'うん。'], ['ううん。', 'ううん。']]) {
  test(`answer word ${input_text} returns unchanged without any upstream request`, async () => {
    const response = await post({ ...input, input_text });
    assert.equal(response.status, 200);
    assert.equal((await response.json()).converted_text, expected);
  });
}

test('real rate binding limits a source, ignores forged XFF, and returns the existing 429 shape', async () => {
  await awayFromMinuteBoundary();
  for (let i = 0; i < 12; i++) {
    assert.equal((await post({ ...input, input_text: 'いいえ' }, {
      ip: '203.0.113.5', headers: { 'X-Forwarded-For': `10.0.0.${i}` },
    })).status, 200);
  }
  const response = await post({ ...input, input_text: 'いいえ' }, { ip: '203.0.113.5' });
  assert.equal(response.status, 429);
  assert.equal(response.headers.get('retry-after'), '60');
  assert.equal(response.headers.get('x-ratelimit-limit'), '12');
  assert.equal(response.headers.get('x-ratelimit-remaining'), '0');
  assert.equal((await response.json()).error.code, 'RATE_LIMIT_EXCEEDED');
  assert.equal((await post({ ...input, input_text: 'いいえ' }, { ip: '203.0.113.6' })).status, 200);
  assert.equal((await post({ ...input, input_text: 'いいえ', previous_result: 'いいえ。' },
    { ip: '203.0.113.5', path: regenerate })).status, 200);
});
test('IPv6 addresses within /64 share the real rate limit, while adjacent /64 is independent', async () => {
  await awayFromMinuteBoundary();
  for (let i = 1; i <= 12; i++) {
    assert.equal((await post({ ...input, input_text: 'はい' }, { ip: `2001:db8:c0de:1::${i}` })).status, 200);
  }
  assert.equal((await post({ ...input, input_text: 'はい' }, { ip: '2001:db8:c0de:1::ff' })).status, 429);
  assert.equal((await post({ ...input, input_text: 'はい' }, { ip: '2001:db8:c0de:2::1' })).status, 200);
});
test('IPv4-mapped IPv6 uses the IPv4 bucket', async () => {
  await awayFromMinuteBoundary();
  for (let i = 0; i < 12; i++) {
    assert.equal((await post({ ...input, input_text: 'はい' }, { ip: '192.0.2.80' })).status, 200);
  }
  assert.equal((await post({ ...input, input_text: 'はい' }, { ip: '::ffff:192.0.2.80' })).status, 429);
});

test('a result that lost the negation is retried with a reminder and the kept negation is returned', async () => {
  let first; let second;
  provider(completion('痛いです。'), 200, ({ body }) => { first = JSON.parse(body).messages[1].content; });
  provider(completion('痛くないです。'), 200, ({ body }) => { second = JSON.parse(body).messages[1].content; });
  const response = await post({ ...input, input_text: 'いたくない' });
  assert.equal(response.status, 200);
  assert.equal((await response.json()).converted_text, '痛くないです。');
  assert.ok(!first.includes('入力の否定は必ず残してください'));
  assert.ok(second.includes('入力の否定は必ず残してください'));
});
for (const [path, extra] of [[convert, {}], [regenerate, { previous_result: '痛くありません。' }]]) {
  test(`${path}: a result that keeps losing the negation is refused and points to the original`, async () => {
    provider(completion('痛いです。')).times(2);
    const response = await post({ ...input, input_text: 'いたくない', ...extra }, { path });
    assert.equal(response.status, 500);
    const { error } = await response.json();
    assert.equal(error.code, 'AI_MEANING_CHANGED');
    assert.equal(error.message, '意味が変わるおそれがあるため、変換を止めました。元の文をお使いください。');
  });
}
for (const [input_text, result] of [
  ['おなかいたくない', 'おなかが痛いです。'], ['さわらないで', '触っていただけませんか。'],
  ['いたくないさむい', '痛いです。寒いです。'], ['いたくないー', '痛いです。'], ['おさないで', '押してください。'],
  ['みえなくなった', '見えるようになりました。'], ['いかないほうがいい', '行くほうがいいです。'],
  ['いたくなく', '痛いです。'], ['いたくなかった', '痛かったです。'], ['ねむれなくて', '眠れます。'],
  ['いたみません', '痛みます。'],
]) {
  test(`${input_text} is refused when the result is ${result}`, async () => {
    provider(completion(result)).times(2);
    const response = await post({ ...input, input_text });
    assert.equal((await response.json()).error.code, 'AI_MEANING_CHANGED');
  });
}
for (const [input_text, result] of [
  ['いきたくない', '行きたくないです。'], ['たべたくない', '食べたくありません。'], ['いらない', 'いりません。'],
  ['さわらないで', '触らないでください。'], ['いたくなかった', '痛くなかったです。'], ['ねむれなくて', '眠れなくて困っています。'],
  ['はないたい', '鼻が痛いです。'], ['きたない', '汚れております。'], ['おさない', '幼いです。'], ['なくなった', '亡くなりました。'],
  ['わからない', 'わかりかねます。'], ['すみません', '恐れ入ります。'], ['あんないして', '案内してください。'],
  ['ないかにいきたい', '内科に行きたいです。'], ['いらない', '不要です。'],
]) {
  test(`${input_text} passes the negation check as ${result}`, async () => {
    provider(completion(result));
    const response = await post({ ...input, input_text });
    assert.equal(response.status, 200);
    assert.equal((await response.json()).converted_text, result);
  });
}

for (const [body, status, code] of [
  [completion('', 'stop'), 500, 'AI_API_ERROR'],
  [completion('意味が途中で切れ', 'length'), 500, 'AI_API_ERROR'],
  [{ choices: [] }, 500, 'AI_API_ERROR'],
  [{ error: 'CANARY-PROVIDER-SECRET' }, 500, 'AI_API_ERROR'],
]) {
  test(`rejects unsafe AI response: ${JSON.stringify(body)}`, async () => {
    provider(body);
    const response = await post();
    assert.equal(response.status, status);
    assert.equal((await response.json()).error.code, code);
  });
}
test('upstream 429 is retried once and translated without its body', async () => {
  provider({ error: 'CANARY-PROVIDER-SECRET' }, 429).times(2);
  const response = await post();
  assert.equal(response.status, 429);
  const text = await response.text();
  assert.ok(text.includes('AI_RATE_LIMIT') && text.includes('元の文'));
  assert.ok(!text.includes('CANARY-PROVIDER-SECRET'));
});
test('network errors retry once and can recover', async () => {
  pending.push({ error: new Error('CANARY-NETWORK-SECRET') });
  provider();
  assert.equal((await post()).status, 200);
});
test('network disconnect while reading the AI response body retries once and can recover', async () => {
  pending.push({ partial: true });
  provider();
  assert.equal((await post()).status, 200);
});
test('complete malformed AI JSON is rejected without retrying or exposing its text', async () => {
  pending.push({ status: 200, raw: '{CANARY-PROVIDER-SECRET' });
  const response = await post();
  assert.equal(response.status, 500);
  const body = await response.text();
  assert.ok(body.includes('AI_API_ERROR'));
  assert.ok(!body.includes('CANARY-PROVIDER-SECRET'));
});
test('upstream 500 is not retried and is sanitized', async () => {
  provider({ error: 'CANARY-PROVIDER-SECRET' }, 500);
  const response = await post();
  assert.equal(response.status, 500);
  assert.equal((await response.json()).error.code, 'AI_API_ERROR');
});
test('upstream deadline produces the existing 504 without a partial result', async () => {
  provider().delay(8500);
  const response = await post();
  assert.equal(response.status, 504);
  assert.equal((await response.json()).error.code, 'AI_API_TIMEOUT');
});
test('CORS preflight accepts the app and unknown origins receive no permission', async () => {
  const response = await worker.dispatchFetch(`http://localhost${convert}`, { method: 'OPTIONS',
    headers: { Origin: 'http://localhost:5173', 'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'content-type,x-api-key' } });
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:5173');
  assert.match(response.headers.get('access-control-allow-headers'), /x-api-key/i);
  const denied = await worker.dispatchFetch('http://localhost/api/v1/health', {
    headers: { Origin: 'https://malicious.example' } });
  assert.equal(denied.headers.get('access-control-allow-origin'), null);
});
test('a missing secret tells the app the service is unavailable, not that it cannot start', async () => {
  const broken = new Miniflare(workerOptions({ WORKERS_AI_GATEWAY_ID: '' }));
  try {
    for (const [path, init] of [[convert, { method: 'POST', body: JSON.stringify(input) }],
      ['/api/v1/health', {}]]) {
      const response = await broken.dispatchFetch(`http://localhost${path}`, init);
      assert.equal(response.status, 503);
      const { error } = await response.json();
      assert.equal(error.code, 'AI_PROVIDER_ERROR');
      assert.equal(error.message, 'AI変換サービスが一時的に利用できません。しばらく待ってから再度お試しください。');
    }
  } finally { await broken.dispose(); }
});
test('a failure leaves its code and cause in the runtime log, without the sentence or the source', async () => {
  provider({ error: 'CANARY-PROVIDER-SECRET' }, 401);
  const response = await post({ ...input, input_text: '失敗の文-CANARY-TEXT' }, { ip: '198.51.100.77' });
  assert.equal(response.status, 500);
  await response.text();
  for (let i = 0; i < 40 && !logs.includes('http_401'); i++) {
    await new Promise(resolve => setTimeout(resolve, 25));
  }
  assert.match(logs, /request_failed/);
  assert.match(logs, /AI_API_ERROR/);
  assert.match(logs, /http_401/);
  assert.ok(!logs.includes('CANARY-'));
  assert.ok(!logs.includes('198.51.100.77'));
});
test('production docs stay private and request/provider canaries never reach runtime logs', async () => {
  for (const path of ['/docs', '/openapi.json']) {
    assert.equal((await worker.dispatchFetch(`http://localhost${path}`)).status, 404);
  }
  assert.ok(!logs.includes('CANARY-'));
  assert.ok(!logs.includes('contract-key-'));
  assert.ok(!logs.includes('upstream-token'));
});
