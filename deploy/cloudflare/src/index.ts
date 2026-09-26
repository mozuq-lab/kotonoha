/**
 * kotonoha backend の前段の Worker。すべてのリクエストを 1 つのコンテナへ渡す。
 *
 * - インスタンスは名前で 1 つに固定する（レート制限はプロセス内メモリ。ADR-002）。
 * - コンテナから見ると送信元はすべてこの Worker になるので、利用者の IP
 *   （Cloudflare が付ける CF-Connecting-IP）で X-Forwarded-For を上書きして渡す。
 *   backend は TRUSTED_PROXY_COUNT=1 でその 1 つだけを読む。利用者が送ってきた
 *   X-Forwarded-For は捨てる（詰めた値で制限を逃れられないように。ADR-002 のデプロイ側契約）。
 * - cf-container-target-port も捨てる（ライブラリはこの値で宛先のポートを差し替える）。
 */
import { Container } from "@cloudflare/containers";
import { env } from "cloudflare:workers";

interface Env {
  BACKEND: DurableObjectNamespace<Backend>;
  API_KEYS: string;
  CF_API_TOKEN: string;
  CF_ACCOUNT_ID: string;
  CF_AI_GATEWAY_ID: string;
}

const secrets = env as unknown as Env;

export class Backend extends Container<Env> {
  defaultPort = 8000;
  // 使われない時間が続いたら止める。最初の 1 回の待ちを避けるため長めにする（費用は常時起動に近い）
  sleepAfter = "24h";
  envVars = {
    ENVIRONMENT: "production",
    TRUSTED_PROXY_COUNT: "1",
    API_KEYS: secrets.API_KEYS,
    CF_API_TOKEN: secrets.CF_API_TOKEN,
    CF_ACCOUNT_ID: secrets.CF_ACCOUNT_ID,
    CF_AI_GATEWAY_ID: secrets.CF_AI_GATEWAY_ID,
  };
}

export function withClientIp(request: Request): Request {
  const headers = new Headers(request.headers);
  headers.delete("X-Forwarded-For");
  headers.delete("cf-container-target-port");
  const ip = request.headers.get("CF-Connecting-IP");
  if (ip) headers.set("X-Forwarded-For", ip);
  return new Request(request, { headers });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    return env.BACKEND.getByName("backend").fetch(withClientIp(request));
  },
} satisfies ExportedHandler<Env>;
