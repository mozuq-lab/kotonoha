# Kotonoha - プロジェクト概要

## 目的
**kotonoha（ことのは）** は文字盤コミュニケーション支援アプリ。
発話困難な方（脳梗塞・ALS・筋疾患など）が、タブレットのタップ操作で自分の言いたいことを適切な丁寧さで伝えられることを目的とする。

## 技術スタック
- **フロントエンド**: Flutter 3.38.1 + Riverpod 2.x (Dart SDK >=3.5.0)
- **バックエンド**: FastAPI 0.121 + SQLAlchemy 2.x + PostgreSQL 15+ (Python 3.10+)
- **インフラ**: Docker + Docker Compose
- **AI**: Anthropic Claude API + OpenAI API（テキスト変換用）

## アーキテクチャ
- **オフラインファースト**: 基本機能はすべてオフライン動作（文字盤、定型文、履歴、TTS）
- **ローカルストレージ**: Hive使用、クラウド同期なし
- **AI変換のみオンライン必須**
- 推奨デバイス: 9.7インチ以上のタブレット

## コードベース構造
```
frontend/kotonoha_app/lib/
├── main.dart, app.dart
├── core/          # constants, themes, router, utils, widgets
├── features/      # 機能モジュール（feature-based）
│   ├── character_board/   # 文字盤
│   ├── preset_phrases/    # 定型文
│   ├── tts/               # 音声読み上げ
│   ├── ai_conversion/     # AI変換
│   ├── favorites/         # お気に入り
│   ├── history/           # 履歴
│   ├── settings/          # 設定
│   ├── emergency/         # 緊急通報
│   ├── help/              # ヘルプ
│   └── ...
├── shared/        # providers, models, services, widgets
└── l10n/          # 多言語化

backend/
├── app/
│   ├── api/       # APIエンドポイント
│   ├── core/      # 設定、認証
│   ├── models/    # SQLAlchemyモデル
│   ├── schemas/   # Pydanticスキーマ
│   ├── crud/      # データアクセス
│   ├── db/        # DB接続
│   └── utils/     # ユーティリティ（AIクライアント等）
├── tests/
└── alembic/       # DBマイグレーション
```

## 主要依存関係
### Flutter
- flutter_riverpod + riverpod_annotation（状態管理）
- go_router（ルーティング）
- hive + hive_flutter（ローカルストレージ）
- dio + retrofit（HTTP通信）
- flutter_tts（音声読み上げ）
- mocktail（テスト）

### Python
- fastapi + uvicorn
- sqlalchemy + asyncpg + alembic
- anthropic + openai（AI API）
- pytest + pytest-asyncio
- ruff + black（リンター/フォーマッター）
