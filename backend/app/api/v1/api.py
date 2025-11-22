"""
API v1 ルーター統合

【機能概要】: 全てのv1エンドポイントルーターを統合
【実装方針】: 各機能のルーターをプレフィックスとタグを設定して登録
"""

from fastapi import APIRouter

from app.api.v1.endpoints import ai, health

api_router = APIRouter()
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(ai.router, prefix="/ai", tags=["ai"])
