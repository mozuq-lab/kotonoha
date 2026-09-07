"""レート制限（ADR-002）。カウンタはプロセス内メモリ。URI も設定キーも無い。

限界: 検出できるのは同一プロセス内だけ。single-worker × 複数 replica は素通しする
（replica 上限はデプロイ側の契約。ADR-002）。
"""

from __future__ import annotations

import math
import time
from collections.abc import Awaitable, Callable

from fastapi import Request
from limits import RateLimitItemPerSecond
from limits.aio.storage import MemoryStorage
from limits.aio.strategies import FixedWindowRateLimiter

from app.errors import RateLimitExceeded


def client_identifier(
    *, forwarded_for: str | None, client_host: str | None, trusted_proxy_count: int
) -> str:
    """信頼する段数分のチェーンが無ければ
    XFF を採用せず接続元へ（フェイルクローズ）。

    過大設定に注意: ``trusted_proxy_count`` に実構成より大きい値を設定すると、
    クライアントが X-Forwarded-For に値を詰めて自分の識別子を選べるようになり、
    レート制限を回避できる（右から N 番目を機械的に採用するため）。実段数と
    一致させること。上流（ALB 等）で受信 XFF を上書きする構成を推奨する
    （ADR-002 のデプロイ側契約）。
    """
    if trusted_proxy_count > 0 and forwarded_for:
        parts = [part.strip() for part in forwarded_for.split(",") if part.strip()]
        if len(parts) >= trusted_proxy_count:
            return parts[-trusted_proxy_count]
    return client_host or "unknown"


class RateLimiter:
    def __init__(self, *, times: int, seconds: int, trusted_proxy_count: int) -> None:
        self._item = RateLimitItemPerSecond(times, seconds)
        self._limiter = FixedWindowRateLimiter(MemoryStorage())
        self._times = times
        self._seconds = seconds
        self._trusted_proxy_count = trusted_proxy_count

    async def hit(self, namespace: str, request: Request) -> None:
        # 同名ヘッダーが複数行だと .get() は先頭の1本しか返さない。RFC 9110 §5.2 では
        # 複数行はカンマ結合と等価なので、全行を結合してから client_identifier に渡す
        # （先頭行に攻撃者が任意文字列を置いて毎回別バケットにするのを防ぐ）。
        identifier = client_identifier(
            forwarded_for=", ".join(request.headers.getlist("x-forwarded-for")) or None,
            client_host=request.client.host if request.client else None,
            trusted_proxy_count=self._trusted_proxy_count,
        )
        if await self._limiter.hit(self._item, namespace, identifier):
            return
        stats = await self._limiter.get_window_stats(self._item, namespace, identifier)
        retry_after = min(self._seconds, max(1, math.ceil(stats.reset_time - time.time())))
        raise RateLimitExceeded(retry_after_seconds=retry_after, limit=self._times)

    def dependency(self, namespace: str) -> Callable[[Request], Awaitable[None]]:
        async def check(request: Request) -> None:
            await self.hit(namespace, request)

        return check
