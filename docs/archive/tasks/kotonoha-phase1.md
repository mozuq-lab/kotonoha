# Phase 1: 開発環境構築・基盤実装

> **この文書は作成当時（2025-11〜）の実装計画の記録です。**
> 記載のバージョン・スキーマ・ディレクトリ構成・コード例には、その後の実装で変更された
> ものが含まれます（例: FastAPI 0.121 / Riverpod 2.x、`ai_conversion_history` テーブル、
> `mobile/` ディレクトリ）。**現行の正は以下を参照してください。**
>
> - 技術スタック・セットアップ: [`README.md`](../../README.md) / [`docs/SETUP.md`](../SETUP.md) / [`docs/tech-stack.md`](../tech-stack.md)
> - 設計・DBスキーマ: [`docs/design/kotonoha/`](../design/kotonoha/)
> - DBスキーマの正: `backend/alembic/versions/` と `backend/app/models/`
>
> 経緯を追う目的以外での参照は避け、この文書自体は歴史記録として更新しません。

## フェーズ概要

- **期間**: Week 1-4 (20営業日)
- **目標**: 開発環境構築、データベース設計、Flutter基盤構築
- **成果物**: 動作する開発環境、DB マイグレーション、Flutter プロジェクト骨格
- **総タスク数**: 20タスク
- **総工数**: 160時間
- **信頼性レベル**: 🟡 黄信号（技術スタック定義書に基づくが、実装手順は推測を含む）

## 🔵 信頼性レベルについて

このフェーズのタスクは、主に `docs/tech-stack.md` の技術スタック定義書に基づいていますが、具体的な実装手順やDocker設定の詳細は推測を含んでいます。EARS要件定義書には環境構築の具体的な手順は記載されていないため、黄信号としています。

## 週次計画

### Week 1: プロジェクト初期設定・Docker環境構築
- **目標**: Docker開発環境構築、Git リポジトリ設定
- **成果物**: docker-compose.yml、README.md、基本設定ファイル

### Week 2: データベース設計・マイグレーション
- **目標**: PostgreSQL セットアップ、Alembic マイグレーション実装
- **成果物**: database-schema.sql実装、マイグレーションファイル

### Week 3: Flutter プロジェクト構造構築
- **目標**: Flutter プロジェクト作成、ディレクトリ構造設計
- **成果物**: Flutter アプリ骨格、Riverpod 設定

### Week 4: 共通コンポーネント・ユーティリティ実装
- **目標**: 共通UIコンポーネント、ユーティリティ関数実装
- **成果物**: 再利用可能なウィジェット、ヘルパー関数

---

## Week 1: プロジェクト初期設定・Docker環境構築

### Day 1: Gitリポジトリ初期設定・プロジェクト構造作成

#### TASK-0001: Gitリポジトリ初期設定
- [x] **タスク完了** ✅ 完了 (2025-11-19)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-501: コードカバレッジ80%以上のテストを維持
- NFR-503: Flutter lints、Ruff + Black準拠のコード品質

**依存タスク**: なし

**実装詳細**:

1. **Gitリポジトリ初期化**:
   - `.gitignore`ファイル作成（Python、Flutter、環境変数ファイル除外）
   - `.gitattributes`作成（改行コード統一）
   - README.md作成（プロジェクト概要、セットアップ手順）
   - LICENSE作成（必要に応じて）

2. **ディレクトリ構造作成**:
   ```
   kotonoha/
   ├── backend/          # FastAPI バックエンド
   │   ├── app/
   │   ├── tests/
   │   ├── alembic/
   │   └── requirements.txt
   ├── frontend/         # Flutter フロントエンド
   │   └── kotonoha_app/
   ├── infra/            # AWS CDK インフラ定義
   │   ├── bin/
   │   ├── lib/
   │   ├── test/
   │   └── cdk.json
   ├── docs/             # ドキュメント
   │   ├── spec/
   │   ├── design/
   │   └── tasks/
   ├── docker/           # Docker設定
   │   ├── backend/
   │   └── postgres/
   ├── .github/          # GitHub Actions CI/CD
   │   └── workflows/
   └── docker-compose.yml
   ```

3. **環境変数テンプレート作成**:
   - `.env.example`作成（API Key、DB接続情報などのテンプレート）
   - 環境変数の説明をREADME.mdに記載

4. **初回コミット**:
   - 基本ファイルをコミット
   - mainブランチ保護設定（GitHub）

**完了条件**:
- [x] Gitリポジトリが作成され、基本的なディレクトリ構造が存在する
- [x] README.mdにプロジェクト概要とセットアップ手順が記載されている
- [x] `.gitignore`で不要なファイルが除外されている
- [x] 環境変数テンプレート（.env.example）が存在する

**テスト要件**: なし（DIRECT）

---

### Day 2: Docker環境構築（PostgreSQL）

#### TASK-0002: PostgreSQL Docker環境構築
- [x] **タスク完了** ✅ 完了 (2025-11-20)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-104: HTTPS通信、API通信を暗号化
- NFR-105: 環境変数をアプリ内にハードコードせず、安全に管理

**依存タスク**: TASK-0001

**実装詳細**:

1. **PostgreSQL Dockerfileおよび設定**:
   - `docker/postgres/Dockerfile`作成（PostgreSQL 15+）
   - 初期化スクリプト作成（`docker/postgres/init.sql`）
   - データベース名: `kotonoha_db`
   - ユーザー名: `kotonoha_user`（環境変数から読み込み）

2. **docker-compose.yml作成**:
   ```yaml
   version: '3.8'
   services:
     postgres:
       build: ./docker/postgres
       container_name: kotonoha_postgres
       environment:
         POSTGRES_USER: ${POSTGRES_USER}
         POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
         POSTGRES_DB: ${POSTGRES_DB}
       ports:
         - "5432:5432"
       volumes:
         - postgres_data:/var/lib/postgresql/data
       networks:
         - kotonoha_network

   volumes:
     postgres_data:

   networks:
     kotonoha_network:
       driver: bridge
   ```

3. **環境変数設定**:
   - `.env.example`にPostgreSQL設定を追加:
     ```
     POSTGRES_USER=kotonoha_user
     POSTGRES_PASSWORD=your_secure_password
     POSTGRES_DB=kotonoha_db
     ```

4. **動作確認**:
   - `docker-compose up -d postgres`でPostgreSQL起動
   - `docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db`で接続確認

**完了条件**:
- [x] PostgreSQLがDockerコンテナで起動する
- [x] 環境変数から設定が読み込まれる
- [x] docker-compose.ymlでPostgreSQLサービスが定義されている
- [x] 外部ツール（psql、pgAdmin）から接続できる

**テスト要件**: なし（DIRECT）

---

### Day 3: Docker環境構築（FastAPIバックエンド）

#### TASK-0003: FastAPI Docker環境構築
- [x] **タスク完了** ✅ 完了 (2025-11-20)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-002: AI変換の応答時間を平均3秒以内
- NFR-104: HTTPS通信、API通信を暗号化

**依存タスク**: TASK-0002

**実装詳細**:

1. **FastAPI Dockerfile作成**:
   - `docker/backend/Dockerfile`:
     ```dockerfile
     FROM python:3.10-slim

     WORKDIR /app

     # システム依存関係インストール
     RUN apt-get update && apt-get install -y \
         gcc \
         postgresql-client \
         && rm -rf /var/lib/apt/lists/*

     # Python依存関係インストール
     COPY backend/requirements.txt .
     RUN pip install --no-cache-dir -r requirements.txt

     # アプリケーションコピー
     COPY backend/ .

     # 実行
     CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
     ```

2. **backend/requirements.txt作成**:
   ```
   fastapi==0.121.0
   uvicorn[standard]==0.34.0
   sqlalchemy==2.0.36
   alembic==1.17.1
   asyncpg==0.30.0
   pydantic==2.10.6
   pydantic-settings==2.7.0
   python-jose[cryptography]==3.3.0
   passlib[bcrypt]==1.7.4
   python-multipart==0.0.20
   httpx==0.28.1
   pytest==8.3.5
   pytest-asyncio==0.25.2
   pytest-cov==6.0.0
   ruff==0.8.5
   black==24.10.0
   ```

3. **docker-compose.ymlにFastAPIサービス追加**:
   ```yaml
   backend:
     build:
       context: .
       dockerfile: ./docker/backend/Dockerfile
     container_name: kotonoha_backend
     environment:
       DATABASE_URL: postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
       SECRET_KEY: ${SECRET_KEY}
     ports:
       - "8000:8000"
     volumes:
       - ./backend:/app
     depends_on:
       - postgres
     networks:
       - kotonoha_network
   ```

4. **FastAPI最小実装**:
   - `backend/app/main.py`作成:
     ```python
     from fastapi import FastAPI

     app = FastAPI(title="kotonoha API", version="1.0.0")

     @app.get("/")
     async def root():
         return {"message": "kotonoha API is running"}

     @app.get("/health")
     async def health_check():
         return {"status": "ok"}
     ```

5. **動作確認**:
   - `docker-compose up -d backend`でFastAPI起動
   - `http://localhost:8000/docs`でSwagger UI確認
   - `http://localhost:8000/health`でヘルスチェック

**完了条件**:
- FastAPIがDockerコンテナで起動する
- Swagger UI（http://localhost:8000/docs）にアクセスできる
- ヘルスチェックエンドポイントが正常応答する
- ホットリロード（--reload）が動作する

**テスト要件**: なし（DIRECT）

---

### Day 4: Python仮想環境・Linter/Formatter設定

#### TASK-0004: Python開発環境設定
- [x] **タスク完了** ✅ 完了 (2025-11-20)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-503: Ruff + Black準拠のコード品質
- NFR-501: コードカバレッジ80%以上のテスト

**依存タスク**: TASK-0003

**実装詳細**:

1. **pyproject.toml作成**:
   - `backend/pyproject.toml`:
     ```toml
     [tool.ruff]
     line-length = 100
     target-version = "py310"
     select = ["E", "F", "I", "N", "W", "B", "ANN", "S", "C90"]
     ignore = ["ANN101", "ANN102", "S101"]

     [tool.ruff.per-file-ignores]
     "tests/*" = ["S101", "ANN"]

     [tool.black]
     line-length = 100
     target-version = ['py310']

     [tool.pytest.ini_options]
     testpaths = ["tests"]
     python_files = "test_*.py"
     python_classes = "Test*"
     python_functions = "test_*"
     asyncio_mode = "auto"
     addopts = "--cov=app --cov-report=html --cov-report=term-missing"

     [tool.coverage.run]
     source = ["app"]
     omit = ["*/tests/*", "*/migrations/*"]

     [tool.coverage.report]
     fail_under = 80
     ```

2. **pre-commit設定**:
   - `.pre-commit-config.yaml`作成:
     ```yaml
     repos:
       - repo: https://github.com/astral-sh/ruff-pre-commit
         rev: v0.8.5
         hooks:
           - id: ruff
             args: [--fix]
       - repo: https://github.com/psf/black
         rev: 24.10.0
         hooks:
           - id: black
     ```

3. **VSCode設定（推奨）**:
   - `.vscode/settings.json`:
     ```json
     {
       "python.linting.enabled": true,
       "python.linting.ruffEnabled": true,
       "python.formatting.provider": "black",
       "editor.formatOnSave": true,
       "python.testing.pytestEnabled": true,
       "python.testing.unittestEnabled": false
     }
     ```

4. **Makefile作成（タスク実行補助）**:
   - `backend/Makefile`:
     ```makefile
     .PHONY: lint format test test-cov

     lint:
         ruff check app tests

     format:
         black app tests
         ruff check app tests --fix

     test:
         pytest

     test-cov:
         pytest --cov=app --cov-report=html --cov-report=term-missing
     ```

5. **動作確認**:
   - `cd backend && make lint`でLintチェック
   - `cd backend && make format`でフォーマット
   - `cd backend && make test`でテスト実行（初期状態は空）

**完了条件**:
- Ruffによる静的解析が実行できる
- Blackによる自動フォーマットが実行できる
- pytestが実行できる（テストケースは空でも可）
- pyproject.tomlで品質基準が設定されている

**テスト要件**: なし（DIRECT）

---

### Day 5: Flutter開発環境セットアップ

#### TASK-0005: Flutter開発環境セットアップ
- [x] **タスク完了** ✅ 完了 (2025-11-20)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-401: iOS 14.0以上、Android 10以上で動作
- NFR-503: Flutter lints準拠のコード品質

**依存タスク**: TASK-0001

**実装詳細**:

1. **Flutter SDK確認**:
   - Flutter 3.38.1以上のインストール確認
   - `flutter doctor`で環境チェック
   - iOS/Android SDKのセットアップ

2. **Flutterプロジェクト作成**:
   - `cd frontend`
   - `flutter create --org com.kotonoha --platforms=ios,android,web kotonoha_app`
   - プロジェクト名: `kotonoha_app`
   - Bundle ID: `com.kotonoha.kotonoha_app`

3. **analysis_options.yaml設定**:
   - `frontend/kotonoha_app/analysis_options.yaml`:
     ```yaml
     include: package:flutter_lints/flutter.yaml

     linter:
       rules:
         - prefer_const_constructors
         - prefer_const_literals_to_create_immutables
         - avoid_print
         - avoid_unnecessary_containers
         - sized_box_for_whitespace
         - use_key_in_widget_constructors
         - prefer_final_fields
         - unnecessary_this

     analyzer:
       exclude:
         - "**/*.g.dart"
         - "**/*.freezed.dart"
       errors:
         invalid_annotation_target: ignore
     ```

4. **VSCode設定（Flutter）**:
   - `.vscode/settings.json`に追加:
     ```json
     {
       "[dart]": {
         "editor.formatOnSave": true,
         "editor.rulers": [80]
       },
       "dart.lineLength": 80
     }
     ```

5. **動作確認**:
   - `cd frontend/kotonoha_app`
   - `flutter pub get`で依存関係解決
   - `flutter analyze`でLintチェック
   - `flutter test`でテスト実行（初期テスト）
   - `flutter run -d chrome`でWeb実行確認

**完了条件**:
- Flutter 3.38.1以上がインストールされている
- `flutter doctor`でエラーがない（または許容できる警告のみ）
- Flutterプロジェクトが作成され、初期状態で実行できる
- `flutter analyze`でエラーがない

**テスト要件**: なし（DIRECT）

---

## Week 2: データベース設計・マイグレーション

### Day 6: データベーススキーマ設計

#### TASK-0006: データベーススキーマ設計・SQL作成
- [x] **タスク完了** ✅ 完了 (2025-11-20)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- REQ-901: AI変換機能（バックエンド側で履歴保存用）
- NFR-304: データベースエラー発生時に適切なエラーハンドリング

**依存タスク**: TASK-0002

**実装詳細**:

1. **database-schema.sql作成**:
   - `docs/design/kotonoha/database-schema.sql`を実装:
   ```sql
   -- AI変換履歴テーブル（将来的な学習・統計用）
   CREATE TABLE ai_conversion_history (
       id SERIAL PRIMARY KEY,
       input_text TEXT NOT NULL,
       converted_text TEXT NOT NULL,
       politeness_level VARCHAR(20) NOT NULL CHECK (politeness_level IN ('casual', 'normal', 'polite')),
       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
       conversion_time_ms INTEGER,
       user_session_id UUID
   );

   -- AI変換履歴のインデックス
   CREATE INDEX idx_ai_conversion_created_at ON ai_conversion_history(created_at DESC);
   CREATE INDEX idx_ai_conversion_session ON ai_conversion_history(user_session_id);

   -- 管理者用テーブル（将来拡張用）
   CREATE TABLE admin_users (
       id SERIAL PRIMARY KEY,
       username VARCHAR(50) UNIQUE NOT NULL,
       hashed_password VARCHAR(255) NOT NULL,
       email VARCHAR(100) UNIQUE,
       is_active BOOLEAN DEFAULT TRUE,
       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
   );
   ```

2. **ERD作成（Mermaid）**:
   - `docs/design/kotonoha/database-erd.md`作成:
   ```markdown
   # データベースER図

   ```mermaid
   erDiagram
       ai_conversion_history {
           serial id PK
           text input_text
           text converted_text
           varchar politeness_level
           timestamp created_at
           integer conversion_time_ms
           uuid user_session_id
       }

       admin_users {
           serial id PK
           varchar username UK
           varchar hashed_password
           varchar email UK
           boolean is_active
           timestamp created_at
           timestamp updated_at
       }
   ```

3. **データベーステーブル説明書作成**:
   - README.mdまたは別ドキュメントにテーブル仕様を記載
   - 各カラムの説明、制約、インデックス、外部キー関係

**完了条件**:
- [x] database-schema.sqlが作成されている
- [x] ERD（Mermaid形式）が作成されている
- [x] テーブル説明書が存在する
- [x] SQLファイルがPostgreSQLで実行可能（文法エラーなし）

**テスト要件**: なし（DIRECT）

---

### Day 7: Alembic初期設定

#### TASK-0007: Alembic初期設定・マイグレーション環境構築
- [x] **タスク完了** ✅ 完了 (2025-11-20)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-304: データベースエラー発生時に適切なエラーハンドリング
- NFR-501: コードカバレッジ80%以上のテスト

**依存タスク**: TASK-0006

**実装詳細**:

1. **Alembic初期化**:
   - `cd backend`
   - `alembic init alembic`
   - `alembic/`ディレクトリが生成される

2. **alembic.ini設定**:
   - `backend/alembic.ini`編集:
   ```ini
   [alembic]
   script_location = alembic
   prepend_sys_path = .
   version_path_separator = os
   sqlalchemy.url = postgresql+asyncpg://%(DB_USER)s:%(DB_PASSWORD)s@%(DB_HOST)s:%(DB_PORT)s/%(DB_NAME)s
   ```

3. **env.py設定**:
   - `backend/alembic/env.py`編集:
   ```python
   import asyncio
   from logging.config import fileConfig
   from sqlalchemy import pool
   from sqlalchemy.engine import Connection
   from sqlalchemy.ext.asyncio import async_engine_from_config
   from alembic import context
   from app.db.base import Base  # 全モデルをインポート
   from app.core.config import settings

   config = context.config

   # 環境変数からDB接続情報を設定
   config.set_main_option("DB_USER", settings.POSTGRES_USER)
   config.set_main_option("DB_PASSWORD", settings.POSTGRES_PASSWORD)
   config.set_main_option("DB_HOST", settings.POSTGRES_HOST)
   config.set_main_option("DB_PORT", str(settings.POSTGRES_PORT))
   config.set_main_option("DB_NAME", settings.POSTGRES_DB)

   target_metadata = Base.metadata

   # ... 非同期マイグレーション設定
   ```

4. **設定ファイル作成**:
   - `backend/app/core/config.py`:
   ```python
   from pydantic_settings import BaseSettings

   class Settings(BaseSettings):
       POSTGRES_USER: str
       POSTGRES_PASSWORD: str
       POSTGRES_HOST: str = "localhost"
       POSTGRES_PORT: int = 5432
       POSTGRES_DB: str
       SECRET_KEY: str

       class Config:
           env_file = ".env"

   settings = Settings()
   ```

5. **動作確認**:
   - `alembic revision --autogenerate -m "Initial migration"`でマイグレーション生成
   - `alembic upgrade head`でマイグレーション実行

**完了条件**:
- [x] Alembicが初期化されている
- [x] alembic.iniが環境変数から設定を読み込む
- [x] env.pyがSQLAlchemyに対応している
- [x] 初期マイグレーションファイルが生成可能（TASK-0008で実施）
- [x] PostgreSQLに接続できる
- [x] `alembic current`コマンドが正常に実行される

**テスト要件**: なし（DIRECT）

**実装記録**: `docs/implements/kotonoha/TASK-0007/`

---

### Day 8: SQLAlchemyモデル実装

#### TASK-0008: SQLAlchemyモデル実装
- [x] **タスク完了** ✅ 完了 (2025-11-20)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- REQ-901: AI変換機能
- NFR-304: データベースエラー発生時に適切なエラーハンドリング

**依存タスク**: TASK-0007

**実装詳細**:

1. **ベースモデル作成**:
   - `backend/app/db/base_class.py`:
   ```python
   from datetime import datetime
   from sqlalchemy import Column, DateTime
   from sqlalchemy.orm import as_declarative, declared_attr

   @as_declarative()
   class Base:
       id: int
       __name__: str

       @declared_attr
       def __tablename__(cls) -> str:
           return cls.__name__.lower()
   ```

2. **AI変換履歴モデル**:
   - `backend/app/models/ai_conversion_history.py`:
   ```python
   from sqlalchemy import Column, Integer, String, Text, DateTime, Enum
   from sqlalchemy.dialects.postgresql import UUID
   from datetime import datetime
   import enum
   from app.db.base_class import Base

   class PolitenessLevel(str, enum.Enum):
       CASUAL = "casual"
       NORMAL = "normal"
       POLITE = "polite"

   class AIConversionHistory(Base):
       __tablename__ = "ai_conversion_history"

       id = Column(Integer, primary_key=True, index=True)
       input_text = Column(Text, nullable=False)
       converted_text = Column(Text, nullable=False)
       politeness_level = Column(Enum(PolitenessLevel), nullable=False)
       created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
       conversion_time_ms = Column(Integer)
       user_session_id = Column(UUID(as_uuid=True))
   ```

3. **モデル集約**:
   - `backend/app/db/base.py`:
   ```python
   from app.db.base_class import Base
   from app.models.ai_conversion_history import AIConversionHistory
   # 将来的な追加モデルもここでインポート
   ```

4. **データベースセッション管理**:
   - `backend/app/db/session.py`:
   ```python
   from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
   from sqlalchemy.orm import sessionmaker
   from app.core.config import settings

   DATABASE_URL = f"postgresql+asyncpg://{settings.POSTGRES_USER}:{settings.POSTGRES_PASSWORD}@{settings.POSTGRES_HOST}:{settings.POSTGRES_PORT}/{settings.POSTGRES_DB}"

   engine = create_async_engine(DATABASE_URL, echo=True)
   async_session_maker = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

   async def get_db():
       async with async_session_maker() as session:
           yield session
   ```

**完了条件**:
- SQLAlchemyモデルが実装されている
- Alembicの自動生成でマイグレーションファイルが作成できる
- `alembic upgrade head`でテーブルが作成される
- データベースにテーブルが存在することを確認できる

**テスト要件**:
- モデルのインスタンス化テスト
- モデルのバリデーションテスト
- データベース接続テスト

---

### Day 9: 初回マイグレーション実行・検証

#### TASK-0009: 初回マイグレーション実行・DB接続テスト
- [x] **タスク完了** ✅ 完了 (2025-11-20) - TDD開発完了 (21テストケース全通過)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- NFR-304: データベースエラー発生時に適切なエラーハンドリング
- NFR-502: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ

**依存タスク**: TASK-0008

**実装詳細**:

1. **マイグレーション生成**:
   - `alembic revision --autogenerate -m "Create ai_conversion_history table"`
   - 生成されたマイグレーションファイルを確認・修正

2. **マイグレーション実行**:
   - `alembic upgrade head`でマイグレーション適用
   - PostgreSQLに接続してテーブル確認:
     ```bash
     docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db
     \dt
     \d ai_conversion_history
     ```

3. **ロールバックテスト**:
   - `alembic downgrade -1`でロールバック
   - `alembic upgrade head`で再適用
   - 正常に動作することを確認

4. **データベース接続テスト実装**:
   - `backend/tests/test_db_connection.py`:
   ```python
   import pytest
   from sqlalchemy import text
   from app.db.session import async_session_maker

   @pytest.mark.asyncio
   async def test_database_connection():
       async with async_session_maker() as session:
           result = await session.execute(text("SELECT 1"))
           assert result.scalar() == 1

   @pytest.mark.asyncio
   async def test_ai_conversion_history_table_exists():
       async with async_session_maker() as session:
           result = await session.execute(
               text("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ai_conversion_history')")
           )
           assert result.scalar() is True
   ```

5. **CRUDテスト実装**:
   - `backend/tests/test_models.py`:
   ```python
   import pytest
   from uuid import uuid4
   from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel
   from app.db.session import async_session_maker

   @pytest.mark.asyncio
   async def test_create_ai_conversion_history():
       async with async_session_maker() as session:
           record = AIConversionHistory(
               input_text="ありがとう",
               converted_text="ありがとうございます",
               politeness_level=PolitenessLevel.POLITE,
               conversion_time_ms=100,
               user_session_id=uuid4()
           )
           session.add(record)
           await session.commit()
           await session.refresh(record)

           assert record.id is not None
           assert record.input_text == "ありがとう"
           assert record.politeness_level == PolitenessLevel.POLITE
   ```

**完了条件**:
- マイグレーションが正常に実行される
- データベースにテーブルが作成されている
- ロールバック・再適用が正常に動作する
- データベース接続テストが全て成功する
- CRUDテストが全て成功する

**テスト要件**:
- データベース接続テスト
- テーブル存在確認テスト
- CRUD操作テスト（作成、読み取り）

---

### Day 10: バックエンド基本API実装

#### TASK-0010: バックエンドヘルスチェック・基本APIエンドポイント実装
- [x] **タスク完了** ✅ 完了 (2025-11-20) - TDD開発完了 (17テストケース全通過)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- NFR-504: API仕様をOpenAPI (Swagger)形式で自動生成
- NFR-502: ビジネスロジック・APIエンドポイントで90%以上のテストカバレッジ

**依存タスク**: TASK-0009

**実装詳細**:

1. **FastAPI main.py改善**:
   - `backend/app/main.py`:
   ```python
   from fastapi import FastAPI, Depends
   from fastapi.middleware.cors import CORSMiddleware
   from sqlalchemy import text
   from sqlalchemy.ext.asyncio import AsyncSession
   from app.db.session import get_db

   app = FastAPI(
       title="kotonoha API",
       version="1.0.0",
       description="文字盤コミュニケーション支援アプリ バックエンドAPI"
   )

   # CORS設定
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["http://localhost:3000", "http://localhost:5173"],
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )

   @app.get("/")
   async def root():
       return {"message": "kotonoha API is running", "version": "1.0.0"}

   @app.get("/health")
   async def health_check(db: AsyncSession = Depends(get_db)):
       try:
           await db.execute(text("SELECT 1"))
           return {"status": "ok", "database": "connected"}
       except Exception as e:
           return {"status": "error", "database": "disconnected", "error": str(e)}
   ```

2. **APIルーター構造作成**:
   - `backend/app/api/__init__.py`
   - `backend/app/api/v1/__init__.py`
   - `backend/app/api/v1/endpoints/__init__.py`

3. **スキーマ定義（Pydantic）**:
   - `backend/app/schemas/health.py`:
   ```python
   from pydantic import BaseModel

   class HealthResponse(BaseModel):
       status: str
       database: str
       error: str | None = None
   ```

4. **APIテスト実装**:
   - `backend/tests/test_api_health.py`:
   ```python
   import pytest
   from httpx import AsyncClient
   from app.main import app

   @pytest.mark.asyncio
   async def test_root_endpoint():
       async with AsyncClient(app=app, base_url="http://test") as client:
           response = await client.get("/")
           assert response.status_code == 200
           assert response.json()["message"] == "kotonoha API is running"

   @pytest.mark.asyncio
   async def test_health_check():
       async with AsyncClient(app=app, base_url="http://test") as client:
           response = await client.get("/health")
           assert response.status_code == 200
           data = response.json()
           assert data["status"] == "ok"
           assert data["database"] == "connected"
   ```

5. **Swagger UI確認**:
   - http://localhost:8000/docs でSwagger UI確認
   - http://localhost:8000/redoc でReDoc確認

**完了条件**:
- [x] ヘルスチェックAPIが実装されている
- [x] Swagger UIでAPI仕様が確認できる
- [x] APIテストが全て成功する
- [x] CORSが正しく設定されている

**テスト要件**:
- [x] ルートエンドポイントテスト (3件)
- [x] ヘルスチェックエンドポイントテスト (6件)
- [x] データベース接続確認テスト
- [x] CORS設定テスト (5件)
- [x] Swagger UI / OpenAPI仕様テスト (3件)

---

## Week 3: Flutter プロジェクト構造構築

### Day 11: Flutterプロジェクトディレクトリ構造設計

#### TASK-0011: Flutterプロジェクトディレクトリ構造設計・実装
- [x] **タスク完了** ✅ 完了 (2025-11-20)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-503: Flutter lints準拠のコード品質
- NFR-501: コードカバレッジ80%以上のテスト

**依存タスク**: TASK-0005

**実装詳細**:

1. **ディレクトリ構造作成**:
   - `frontend/kotonoha_app/lib/`に以下の構造を作成:
   ```
   lib/
   ├── main.dart
   ├── app.dart
   ├── core/
   │   ├── constants/
   │   │   ├── app_colors.dart
   │   │   ├── app_text_styles.dart
   │   │   └── app_sizes.dart
   │   ├── themes/
   │   │   ├── light_theme.dart
   │   │   ├── dark_theme.dart
   │   │   └── high_contrast_theme.dart
   │   ├── router/
   │   │   └── app_router.dart
   │   └── utils/
   │       └── logger.dart
   ├── features/
   │   ├── character_board/
   │   │   ├── data/
   │   │   ├── domain/
   │   │   ├── presentation/
   │   │   └── providers/
   │   ├── preset_phrases/
   │   ├── large_buttons/
   │   ├── emergency/
   │   ├── tts/
   │   ├── history/
   │   ├── favorites/
   │   └── settings/
   ├── shared/
   │   ├── widgets/
   │   ├── models/
   │   └── services/
   └── l10n/
       └── app_ja.arb
   ```

2. **定数ファイル作成**:
   - `lib/core/constants/app_colors.dart`:
   ```dart
   import 'package:flutter/material.dart';

   class AppColors {
     // ライトモード
     static const Color primaryLight = Color(0xFF2196F3);
     static const Color backgroundLight = Color(0xFFFFFFFF);

     // ダークモード
     static const Color primaryDark = Color(0xFF1976D2);
     static const Color backgroundDark = Color(0xFF121212);

     // 高コントラストモード
     static const Color primaryHighContrast = Color(0xFF000000);
     static const Color backgroundHighContrast = Color(0xFFFFFFFF);

     // 緊急ボタン
     static const Color emergency = Color(0xFFD32F2F);
   }
   ```

   - `lib/core/constants/app_sizes.dart`:
   ```dart
   class AppSizes {
     // タップターゲット最小サイズ (REQ-5001)
     static const double minTapTarget = 44.0;
     static const double recommendedTapTarget = 60.0;

     // フォントサイズ (REQ-801)
     static const double fontSizeSmall = 16.0;
     static const double fontSizeMedium = 20.0;
     static const double fontSizeLarge = 24.0;

     // 余白
     static const double paddingSmall = 8.0;
     static const double paddingMedium = 16.0;
     static const double paddingLarge = 24.0;
   }
   ```

3. **README更新**:
   - `frontend/kotonoha_app/README.md`にディレクトリ構造の説明を追加

**完了条件**:
- [x] ディレクトリ構造が作成されている
- [x] 定数ファイルが実装されている
- [x] 各ディレクトリにREADME.md（説明）が存在する
- [x] Flutter analyzeでエラーがない

**テスト要件**: なし（DIRECT）

**実装記録**: `docs/implements/kotonoha/TASK-0011/`

---

### Day 12: Flutter依存パッケージ追加・設定

#### TASK-0012: Flutter依存パッケージ追加・pubspec.yaml設定
- [x] **タスク完了** ✅ 完了 (2025-11-20) - 検証完了 (依存パッケージ追加・設定完了)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- REQ-401: OS標準TTSで読み上げ
- REQ-601: 履歴をローカル端末内に保存

**依存タスク**: TASK-0011

**実装詳細**:

1. **pubspec.yaml編集**:
   - `frontend/kotonoha_app/pubspec.yaml`:
   ```yaml
   name: kotonoha_app
   description: 文字盤コミュニケーション支援アプリ
   version: 1.0.0+1

   environment:
     sdk: '>=3.5.0 <4.0.0'

   dependencies:
     flutter:
       sdk: flutter

     # 状態管理
     flutter_riverpod: ^2.6.1
     riverpod_annotation: ^2.6.1

     # ルーティング
     go_router: ^14.6.2

     # ローカルストレージ
     shared_preferences: ^2.3.4
     hive: ^2.2.3
     hive_flutter: ^1.1.0

     # HTTP通信
     dio: ^5.7.0
     retrofit: ^4.4.1

     # JSON
     json_annotation: ^4.9.0

     # TTS（音声読み上げ）
     flutter_tts: ^4.2.0

     # ロギング
     logger: ^2.5.0

     # 多言語化
     intl: ^0.20.1
     flutter_localizations:
       sdk: flutter

   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^5.0.0

     # コード生成
     build_runner: ^2.4.14
     riverpod_generator: ^2.6.3
     hive_generator: ^2.0.1
     json_serializable: ^6.9.2
     retrofit_generator: ^9.1.4

     # テスト
     mocktail: ^1.0.4

   flutter:
     uses-material-design: true
     generate: true
   ```

2. **依存関係インストール**:
   - `cd frontend/kotonoha_app`
   - `flutter pub get`

3. **コード生成設定**:
   - `build.yaml`作成:
   ```yaml
   targets:
     $default:
       builders:
         riverpod_generator:
           options:
             riverpod_generator:
               generate_riverpod_annotation: true
   ```

4. **動作確認**:
   - `flutter pub get`でエラーがないこと
   - `flutter pub outdated`で依存関係確認

**完了条件**:
- [x] pubspec.yamlに必要な依存パッケージが追加されている
- [x] `flutter pub get`でエラーがない
- [x] 各パッケージが最新安定版である
- [x] build.yamlが作成されRiverpod設定が正しい
- [x] `flutter analyze`でエラーがない
- [x] コード生成（build_runner）が正常に動作する

**テスト要件**: なし（DIRECT）

**実装記録**: `docs/implements/kotonoha/TASK-0012/`

---

### Day 13: Riverpod状態管理セットアップ

#### TASK-0013: Riverpod状態管理セットアップ・プロバイダー基盤実装
- [x] **タスク完了** ✅ 完了 (2025-11-20) - TDD開発完了 (13テストケース全通過、要件網羅率100%)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- REQ-801: フォントサイズを3段階から選択
- REQ-803: 3つのテーマを提供

**依存タスク**: TASK-0012

**実装詳細**:

1. **main.dartセットアップ**:
   - `lib/main.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:hive_flutter/hive_flutter.dart';
   import 'app.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     // Hive初期化
     await Hive.initFlutter();

     runApp(
       const ProviderScope(
         child: KotonohaApp(),
       ),
     );
   }
   ```

2. **app.dart実装**:
   - `lib/app.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:go_router/go_router.dart';
   import 'core/router/app_router.dart';
   import 'core/themes/light_theme.dart';
   import 'core/themes/dark_theme.dart';

   class KotonohaApp extends ConsumerWidget {
     const KotonohaApp({super.key});

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final router = ref.watch(routerProvider);

       return MaterialApp.router(
         title: 'kotonoha',
         theme: lightTheme,
         darkTheme: darkTheme,
         routerConfig: router,
       );
     }
   }
   ```

3. **設定プロバイダー実装**:
   - `lib/features/settings/providers/settings_provider.dart`:
   ```dart
   import 'package:riverpod_annotation/riverpod_annotation.dart';
   import 'package:shared_preferences/shared_preferences.dart';

   part 'settings_provider.g.dart';

   enum FontSize { small, medium, large }
   enum ThemeMode { light, dark, highContrast }

   @riverpod
   class SettingsNotifier extends _$SettingsNotifier {
     late SharedPreferences _prefs;

     @override
     Future<Settings> build() async {
       _prefs = await SharedPreferences.getInstance();
       return Settings(
         fontSize: FontSize.values[_prefs.getInt('fontSize') ?? 1],
         themeMode: ThemeMode.values[_prefs.getInt('themeMode') ?? 0],
       );
     }

     Future<void> setFontSize(FontSize size) async {
       await _prefs.setInt('fontSize', size.index);
       state = AsyncValue.data(
         state.value!.copyWith(fontSize: size),
       );
     }

     Future<void> setThemeMode(ThemeMode mode) async {
       await _prefs.setInt('themeMode', mode.index);
       state = AsyncValue.data(
         state.value!.copyWith(themeMode: mode),
       );
     }
   }

   class Settings {
     final FontSize fontSize;
     final ThemeMode themeMode;

     Settings({required this.fontSize, required this.themeMode});

     Settings copyWith({FontSize? fontSize, ThemeMode? themeMode}) {
       return Settings(
         fontSize: fontSize ?? this.fontSize,
         themeMode: themeMode ?? this.themeMode,
       );
     }
   }
   ```

4. **コード生成**:
   - `flutter pub run build_runner build --delete-conflicting-outputs`

5. **テスト実装**:
   - `test/features/settings/providers/settings_provider_test.dart`:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

   void main() {
     group('SettingsNotifier', () {
       test('初期状態がmedium、lightであること', () async {
         final container = ProviderContainer();
         final settings = await container.read(settingsNotifierProvider.future);

         expect(settings.fontSize, FontSize.medium);
         expect(settings.themeMode, ThemeMode.light);
       });
     });
   }
   ```

**完了条件**:
- [x] Riverpod ProviderScopeが設定されている
- [x] 設定プロバイダーが実装されている
- [x] コード生成が正常に動作する
- [x] テストが全て成功する

**テスト要件**:
- [x] 設定プロバイダーの初期状態テスト (TC-001)
- [x] フォントサイズ変更テスト (TC-002, TC-004, TC-015)
- [x] テーマモード変更テスト (TC-005, TC-006, TC-007, TC-016)
- [x] 設定永続化テスト (TC-008, TC-009)
- [x] エラーハンドリングテスト (TC-011, TC-012, TC-014)

**実装記録**: `docs/implements/kotonoha/TASK-0013/`

---

### Day 14: Hiveローカルストレージセットアップ

#### TASK-0014: Hiveローカルストレージセットアップ・データモデル実装
- [x] **タスク完了** ✅ 完了 (2025-11-21) - TDD開発完了 (28テストケース全通過、要件網羅率100%)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- REQ-601: 履歴をローカル端末内に保存
- REQ-5003: データ永続化機構を実装

**依存タスク**: TASK-0013

**実装詳細**:

1. **Hiveアダプター・モデル実装**:
   - `lib/shared/models/history_item.dart`:
   ```dart
   import 'package:hive/hive.dart';

   part 'history_item.g.dart';

   @HiveType(typeId: 0)
   class HistoryItem {
     @HiveField(0)
     final String id;

     @HiveField(1)
     final String text;

     @HiveField(2)
     final DateTime createdAt;

     @HiveField(3)
     final bool isFavorite;

     HistoryItem({
       required this.id,
       required this.text,
       required this.createdAt,
       this.isFavorite = false,
     });
   }
   ```

   - `lib/shared/models/preset_phrase.dart`:
   ```dart
   import 'package:hive/hive.dart';

   part 'preset_phrase.g.dart';

   @HiveType(typeId: 1)
   class PresetPhrase {
     @HiveField(0)
     final String id;

     @HiveField(1)
     final String text;

     @HiveField(2)
     final String category;

     @HiveField(3)
     final bool isFavorite;

     @HiveField(4)
     final int order;

     PresetPhrase({
       required this.id,
       required this.text,
       required this.category,
       this.isFavorite = false,
       required this.order,
     });
   }
   ```

2. **Hive初期化**:
   - `lib/core/utils/hive_init.dart`:
   ```dart
   import 'package:hive_flutter/hive_flutter.dart';
   import 'package:kotonoha_app/shared/models/history_item.dart';
   import 'package:kotonoha_app/shared/models/preset_phrase.dart';

   Future<void> initHive() async {
     await Hive.initFlutter();

     // アダプター登録
     Hive.registerAdapter(HistoryItemAdapter());
     Hive.registerAdapter(PresetPhraseAdapter());

     // ボックスオープン
     await Hive.openBox<HistoryItem>('history');
     await Hive.openBox<PresetPhrase>('presetPhrases');
   }
   ```

3. **main.dartに統合**:
   - `lib/main.dart`を更新:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     await initHive();

     runApp(const ProviderScope(child: KotonohaApp()));
   }
   ```

4. **コード生成**:
   - `flutter pub run build_runner build --delete-conflicting-outputs`

5. **テスト実装**:
   - `test/shared/models/history_item_test.dart`:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:hive_flutter/hive_flutter.dart';
   import 'package:kotonoha_app/shared/models/history_item.dart';

   void main() {
     setUp(() async {
       await Hive.initFlutter();
       Hive.registerAdapter(HistoryItemAdapter());
     });

     tearDown(() async {
       await Hive.deleteFromDisk();
     });

     test('HistoryItemの保存・読み込み', () async {
       final box = await Hive.openBox<HistoryItem>('test_history');

       final item = HistoryItem(
         id: '1',
         text: 'ありがとう',
         createdAt: DateTime.now(),
       );

       await box.put(item.id, item);
       final retrieved = box.get(item.id);

       expect(retrieved!.text, 'ありがとう');
       expect(retrieved.isFavorite, false);

       await box.close();
     });
   }
   ```

**完了条件**:
- Hiveアダプターが実装されている
- コード生成が正常に動作する
- Hiveボックスが正常にオープンできる
- テストが全て成功する

**テスト要件**:
- HistoryItemの保存・読み込みテスト
- PresetPhraseの保存・読み込みテスト
- Hiveボックスのオープン・クローズテスト

---

### Day 15: go_routerナビゲーション設定

#### TASK-0015: go_routerナビゲーション設定・ルーティング実装
- [x] **タスク完了** ✅ 完了 (2025-11-22) - TDD開発完了 (34テストケース全通過)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- NFR-203: 画面遷移を必要最小限に留める
- REQ-5005: タップ主体の操作で完結

**依存タスク**: TASK-0014

**実装詳細**:

1. **ルート定義**:
   - `lib/core/router/app_router.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:go_router/go_router.dart';
   import 'package:riverpod_annotation/riverpod_annotation.dart';

   part 'app_router.g.dart';

   @riverpod
   GoRouter router(RouterRef ref) {
     return GoRouter(
       initialLocation: '/',
       routes: [
         GoRoute(
           path: '/',
           name: 'home',
           builder: (context, state) => const HomeScreen(),
         ),
         GoRoute(
           path: '/settings',
           name: 'settings',
           builder: (context, state) => const SettingsScreen(),
         ),
         GoRoute(
           path: '/history',
           name: 'history',
           builder: (context, state) => const HistoryScreen(),
         ),
         GoRoute(
           path: '/favorites',
           name: 'favorites',
           builder: (context, state) => const FavoritesScreen(),
         ),
       ],
       errorBuilder: (context, state) => ErrorScreen(error: state.error),
     );
   }
   ```

2. **画面スケルトン作成**:
   - `lib/features/character_board/presentation/home_screen.dart`:
   ```dart
   import 'package:flutter/material.dart';

   class HomeScreen extends StatelessWidget {
     const HomeScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('kotonoha')),
         body: const Center(child: Text('ホーム画面')),
       );
     }
   }
   ```

   - 同様に`SettingsScreen`、`HistoryScreen`、`FavoritesScreen`、`ErrorScreen`を作成

3. **ナビゲーションテスト実装**:
   - `test/core/router/app_router_test.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:go_router/go_router.dart';
   import 'package:kotonoha_app/core/router/app_router.dart';

   void main() {
     testWidgets('初期ルートが/であること', (tester) async {
       final container = ProviderContainer();
       final router = container.read(routerProvider);

       await tester.pumpWidget(
         MaterialApp.router(
           routerConfig: router,
         ),
       );

       expect(find.text('ホーム画面'), findsOneWidget);
     });

     testWidgets('/settingsへのナビゲーション', (tester) async {
       final container = ProviderContainer();
       final router = container.read(routerProvider);

       await tester.pumpWidget(
         MaterialApp.router(
           routerConfig: router,
         ),
       );

       router.go('/settings');
       await tester.pumpAndSettle();

       expect(find.text('設定画面'), findsOneWidget);
     });
   }
   ```

**完了条件**:
- go_routerが設定されている
- 主要画面（ホーム、設定、履歴、お気に入り）へのルーティングが動作する
- ナビゲーションテストが全て成功する

**テスト要件**:
- 初期ルート確認テスト
- 各画面へのナビゲーションテスト
- エラーページ表示テスト

---

## Week 4: 共通コンポーネント・ユーティリティ実装

### Day 16: テーマ実装（ライト・ダーク・高コントラスト）

#### TASK-0016: テーマ実装（ライト・ダーク・高コントラスト）
- [x] **タスク完了** (2025-11-22)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- REQ-803: 3つのテーマを提供
- REQ-5006: 高コントラストモードでWCAG 2.1 AAレベルのコントラスト比

**依存タスク**: TASK-0015

**実装詳細**:

1. **ライトテーマ実装**:
   - `lib/core/themes/light_theme.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:kotonoha_app/core/constants/app_colors.dart';
   import 'package:kotonoha_app/core/constants/app_sizes.dart';

   final ThemeData lightTheme = ThemeData(
     brightness: Brightness.light,
     colorScheme: ColorScheme.light(
       primary: AppColors.primaryLight,
       background: AppColors.backgroundLight,
       error: AppColors.emergency,
     ),
     textTheme: TextTheme(
       bodyLarge: TextStyle(fontSize: AppSizes.fontSizeMedium),
       bodyMedium: TextStyle(fontSize: AppSizes.fontSizeMedium),
       titleLarge: TextStyle(fontSize: AppSizes.fontSizeLarge),
     ),
     elevatedButtonTheme: ElevatedButtonThemeData(
       style: ElevatedButton.styleFrom(
         minimumSize: Size(
           AppSizes.recommendedTapTarget,
           AppSizes.recommendedTapTarget,
         ),
       ),
     ),
   );
   ```

2. **ダークテーマ実装**:
   - `lib/core/themes/dark_theme.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:kotonoha_app/core/constants/app_colors.dart';

   final ThemeData darkTheme = ThemeData(
     brightness: Brightness.dark,
     colorScheme: ColorScheme.dark(
       primary: AppColors.primaryDark,
       background: AppColors.backgroundDark,
       error: AppColors.emergency,
     ),
     // ライトテーマと同様の設定
   );
   ```

3. **高コントラストテーマ実装**:
   - `lib/core/themes/high_contrast_theme.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:kotonoha_app/core/constants/app_colors.dart';

   final ThemeData highContrastTheme = ThemeData(
     brightness: Brightness.light,
     colorScheme: ColorScheme.light(
       primary: AppColors.primaryHighContrast,
       background: AppColors.backgroundHighContrast,
       onBackground: Colors.black,
       error: AppColors.emergency,
     ),
     // WCAG 2.1 AA準拠のコントラスト比設定
   );
   ```

4. **テーマプロバイダー実装**:
   - `lib/core/themes/theme_provider.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:riverpod_annotation/riverpod_annotation.dart';
   import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
   import 'light_theme.dart';
   import 'dark_theme.dart';
   import 'high_contrast_theme.dart';

   part 'theme_provider.g.dart';

   @riverpod
   ThemeData currentTheme(CurrentThemeRef ref) {
     final settings = ref.watch(settingsNotifierProvider).value;

     switch (settings?.themeMode) {
       case ThemeMode.dark:
         return darkTheme;
       case ThemeMode.highContrast:
         return highContrastTheme;
       case ThemeMode.light:
       default:
         return lightTheme;
     }
   }
   ```

5. **テスト実装**:
   - `test/core/themes/theme_test.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:kotonoha_app/core/themes/light_theme.dart';
   import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';

   void main() {
     test('ライトテーマのコントラスト比', () {
       final background = lightTheme.colorScheme.background;
       final onBackground = lightTheme.colorScheme.onBackground;

       // コントラスト比計算のテスト（簡易版）
       expect(background, isNotNull);
       expect(onBackground, isNotNull);
     });

     test('高コントラストテーマのコントラスト比がWCAG AA準拠', () {
       // コントラスト比4.5:1以上を確認
       final background = highContrastTheme.colorScheme.background;
       final onBackground = highContrastTheme.colorScheme.onBackground;

       expect(background.computeLuminance(), greaterThan(0.8));
       expect(onBackground.computeLuminance(), lessThan(0.2));
     });
   }
   ```

**完了条件**:
- 3つのテーマが実装されている
- 高コントラストテーマがWCAG 2.1 AA準拠している
- テーマプロバイダーが正常に動作する
- テストが全て成功する

**テスト要件**:
- 各テーマのカラースキームテスト
- コントラスト比計算テスト
- テーマ切り替えテスト

---

### Day 17: 共通UIコンポーネント実装（ボタン・入力欄）

#### TASK-0017: 共通UIコンポーネント実装（大ボタン・入力欄）
- [x] **タスク完了** ✅ 完了 (2025-11-22)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- REQ-5001: タップターゲットのサイズを44px × 44px以上
- NFR-202: ボタンを視認性が高く押しやすいサイズで設計

**依存タスク**: TASK-0016

**実装詳細**:

1. **大ボタンウィジェット実装**:
   - `lib/shared/widgets/large_button.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:kotonoha_app/core/constants/app_sizes.dart';

   class LargeButton extends StatelessWidget {
     final String label;
     final VoidCallback onPressed;
     final Color? backgroundColor;
     final Color? textColor;
     final double? width;
     final double? height;

     const LargeButton({
       super.key,
       required this.label,
       required this.onPressed,
       this.backgroundColor,
       this.textColor,
       this.width,
       this.height,
     });

     @override
     Widget build(BuildContext context) {
       return SizedBox(
         width: width ?? AppSizes.recommendedTapTarget,
         height: height ?? AppSizes.recommendedTapTarget,
         child: ElevatedButton(
           onPressed: onPressed,
           style: ElevatedButton.styleFrom(
             backgroundColor: backgroundColor,
             foregroundColor: textColor,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(8),
             ),
           ),
           child: Text(
             label,
             style: TextStyle(
               fontSize: AppSizes.fontSizeMedium,
               fontWeight: FontWeight.bold,
             ),
           ),
         ),
       );
     }
   }
   ```

2. **入力欄ウィジェット実装**:
   - `lib/shared/widgets/text_input_field.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:kotonoha_app/core/constants/app_sizes.dart';

   class TextInputField extends StatelessWidget {
     final TextEditingController controller;
     final String? hintText;
     final int? maxLength;
     final VoidCallback? onClear;

     const TextInputField({
       super.key,
       required this.controller,
       this.hintText,
       this.maxLength = 1000,
       this.onClear,
     });

     @override
     Widget build(BuildContext context) {
       return TextField(
         controller: controller,
         maxLength: maxLength,
         maxLines: null,
         style: TextStyle(fontSize: AppSizes.fontSizeLarge),
         decoration: InputDecoration(
           hintText: hintText ?? '文字を入力してください',
           border: OutlineInputBorder(),
           suffixIcon: onClear != null
               ? IconButton(
                   icon: const Icon(Icons.clear),
                   onPressed: onClear,
                   iconSize: AppSizes.minTapTarget,
                 )
               : null,
         ),
       );
     }
   }
   ```

3. **緊急ボタンウィジェット実装**:
   - `lib/shared/widgets/emergency_button.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:kotonoha_app/core/constants/app_colors.dart';
   import 'package:kotonoha_app/core/constants/app_sizes.dart';

   class EmergencyButton extends StatelessWidget {
     final VoidCallback onPressed;

     const EmergencyButton({super.key, required this.onPressed});

     @override
     Widget build(BuildContext context) {
       return SizedBox(
         width: AppSizes.recommendedTapTarget,
         height: AppSizes.recommendedTapTarget,
         child: ElevatedButton(
           onPressed: onPressed,
           style: ElevatedButton.styleFrom(
             backgroundColor: AppColors.emergency,
             foregroundColor: Colors.white,
             shape: const CircleBorder(),
           ),
           child: const Icon(Icons.notifications_active, size: 32),
         ),
       );
     }
   }
   ```

4. **テスト実装**:
   - `test/shared/widgets/large_button_test.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';
   import 'package:kotonoha_app/shared/widgets/large_button.dart';
   import 'package:kotonoha_app/core/constants/app_sizes.dart';

   void main() {
     testWidgets('LargeButtonのサイズが推奨値以上', (tester) async {
       await tester.pumpWidget(
         MaterialApp(
           home: Scaffold(
             body: LargeButton(
               label: 'テスト',
               onPressed: () {},
             ),
           ),
         ),
       );

       final button = tester.widget<SizedBox>(find.byType(SizedBox).first);
       expect(button.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
       expect(button.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
     });

     testWidgets('LargeButtonのタップイベント', (tester) async {
       bool tapped = false;

       await tester.pumpWidget(
         MaterialApp(
           home: Scaffold(
             body: LargeButton(
               label: 'テスト',
               onPressed: () => tapped = true,
             ),
           ),
         ),
       );

       await tester.tap(find.byType(LargeButton));
       expect(tapped, true);
     });
   }
   ```

**完了条件**:
- 大ボタンウィジェットが実装されている
- 入力欄ウィジェットが実装されている
- 緊急ボタンウィジェットが実装されている
- タップターゲットサイズが要件を満たしている
- テストが全て成功する

**テスト要件**:
- ボタンサイズ確認テスト
- タップイベント動作テスト
- ウィジェットレンダリングテスト

---

### Day 18: ユーティリティ関数実装（Logger、バリデーション）

#### TASK-0018: ユーティリティ関数実装（Logger、バリデーション、エラーハンドリング）
- [x] **タスク完了** ✅ 完了 (2025-11-22) - TDD開発完了 (75テストケース全通過、カバレッジ94.5%)

**推定工数**: 8時間

**タスクタイプ**: TDD

**要件名**: kotonoha

**関連要件**:
- NFR-204: エラーメッセージを分かりやすい日本語で表示
- NFR-301: 重大なエラーが発生しても基本機能を継続利用可能に保つ

**依存タスク**: TASK-0017

**実装詳細**:

1. **Loggerユーティリティ実装**:
   - `lib/core/utils/logger.dart`:
   ```dart
   import 'package:logger/logger.dart';

   class AppLogger {
     static final Logger _logger = Logger(
       printer: PrettyPrinter(
         methodCount: 2,
         errorMethodCount: 8,
         lineLength: 120,
         colors: true,
         printEmojis: true,
         printTime: true,
       ),
     );

     static void debug(String message) => _logger.d(message);
     static void info(String message) => _logger.i(message);
     static void warning(String message) => _logger.w(message);
     static void error(String message, [dynamic error, StackTrace? stackTrace]) {
       _logger.e(message, error: error, stackTrace: stackTrace);
     }
   }
   ```

2. **バリデーションユーティリティ実装**:
   - `lib/core/utils/validators.dart`:
   ```dart
   class Validators {
     static const int maxInputLength = 1000;
     static const int maxPresetPhraseLength = 500;
     static const int minAiConversionLength = 2;

     static String? validateInputText(String? text) {
       if (text == null || text.isEmpty) {
         return null;  // 空は許可
       }
       if (text.length > maxInputLength) {
         return '入力は${maxInputLength}文字以内にしてください';
       }
       return null;
     }

     static String? validatePresetPhrase(String? text) {
       if (text == null || text.isEmpty) {
         return '定型文を入力してください';
       }
       if (text.length > maxPresetPhraseLength) {
         return '定型文は${maxPresetPhraseLength}文字以内にしてください';
       }
       return null;
     }

     static bool canConvertWithAi(String text) {
       return text.length >= minAiConversionLength;
     }
   }
   ```

3. **エラーハンドリングユーティリティ実装**:
   - `lib/core/utils/error_handler.dart`:
   ```dart
   import 'package:flutter/material.dart';
   import 'package:kotonoha_app/core/utils/logger.dart';

   class ErrorHandler {
     static void handleError(
       BuildContext context,
       dynamic error,
       StackTrace? stackTrace, {
       String? userMessage,
     }) {
       AppLogger.error('エラーが発生しました', error, stackTrace);

       final message = userMessage ?? _getErrorMessage(error);

       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(message),
           backgroundColor: Colors.red,
           action: SnackBarAction(
             label: '閉じる',
             textColor: Colors.white,
             onPressed: () {},
           ),
         ),
       );
     }

     static String _getErrorMessage(dynamic error) {
       if (error is NetworkException) {
         return 'ネットワークエラーが発生しました。接続を確認してください。';
       }
       if (error is TimeoutException) {
         return '通信がタイムアウトしました。もう一度お試しください。';
       }
       return '予期しないエラーが発生しました。';
     }
   }

   class NetworkException implements Exception {
     final String message;
     NetworkException(this.message);
   }

   class TimeoutException implements Exception {
     final String message;
     TimeoutException(this.message);
   }
   ```

4. **テスト実装**:
   - `test/core/utils/validators_test.dart`:
   ```dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:kotonoha_app/core/utils/validators.dart';

   void main() {
     group('Validators', () {
       test('空文字はvalidateInputTextでnullを返す', () {
         expect(Validators.validateInputText(''), null);
         expect(Validators.validateInputText(null), null);
       });

       test('1000文字を超えるとエラーメッセージを返す', () {
         final longText = 'あ' * 1001;
         final result = Validators.validateInputText(longText);
         expect(result, isNotNull);
         expect(result, contains('1000文字以内'));
       });

       test('AI変換は2文字以上で可能', () {
         expect(Validators.canConvertWithAi('あ'), false);
         expect(Validators.canConvertWithAi('ああ'), true);
       });
     });
   }
   ```

**完了条件**:
- Loggerユーティリティが実装されている
- バリデーションユーティリティが実装されている
- エラーハンドリングユーティリティが実装されている
- テストが全て成功する

**テスト要件**:
- バリデーション関数のテスト
- エラーメッセージ生成テスト
- Logger出力テスト

---

### Day 19: CI/CDパイプライン設定（GitHub Actions）

#### TASK-0019: CI/CDパイプライン設定（GitHub Actions）
- [x] **タスク完了** ✅ 完了 (2025-11-22)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-501: コードカバレッジ80%以上のテスト
- NFR-503: Flutter lints、Ruff + Black準拠のコード品質

**依存タスク**: TASK-0018

**実装詳細**:

1. **Flutter CI/CDワークフロー作成**:
   - `.github/workflows/flutter.yml`:
   ```yaml
   name: Flutter CI

   on:
     push:
       branches: [main, develop]
     pull_request:
       branches: [main, develop]

   jobs:
     test:
       runs-on: ubuntu-latest

       steps:
         - uses: actions/checkout@v4

         - name: Setup Flutter
           uses: subosito/flutter-action@v2
           with:
             flutter-version: '3.38.1'
             channel: 'stable'

         - name: Install dependencies
           working-directory: ./frontend/kotonoha_app
           run: flutter pub get

         - name: Run code generation
           working-directory: ./frontend/kotonoha_app
           run: flutter pub run build_runner build --delete-conflicting-outputs

         - name: Analyze code
           working-directory: ./frontend/kotonoha_app
           run: flutter analyze

         - name: Run tests
           working-directory: ./frontend/kotonoha_app
           run: flutter test --coverage

         - name: Upload coverage
           uses: codecov/codecov-action@v4
           with:
             files: ./frontend/kotonoha_app/coverage/lcov.info
             flags: flutter
   ```

2. **Python CI/CDワークフロー作成**:
   - `.github/workflows/python.yml`:
   ```yaml
   name: Python CI

   on:
     push:
       branches: [main, develop]
     pull_request:
       branches: [main, develop]

   jobs:
     test:
       runs-on: ubuntu-latest

       services:
         postgres:
           image: postgres:15
           env:
             POSTGRES_USER: test_user
             POSTGRES_PASSWORD: test_password
             POSTGRES_DB: test_db
           options: >-
             --health-cmd pg_isready
             --health-interval 10s
             --health-timeout 5s
             --health-retries 5
           ports:
             - 5432:5432

       steps:
         - uses: actions/checkout@v4

         - name: Setup Python
           uses: actions/setup-python@v5
           with:
             python-version: '3.10'

         - name: Install dependencies
           working-directory: ./backend
           run: |
             pip install -r requirements.txt

         - name: Run Ruff lint
           working-directory: ./backend
           run: ruff check app tests

         - name: Run Black format check
           working-directory: ./backend
           run: black --check app tests

         - name: Run tests
           working-directory: ./backend
           env:
             DATABASE_URL: postgresql+asyncpg://test_user:test_password@localhost:5432/test_db
           run: pytest --cov=app --cov-report=xml

         - name: Upload coverage
           uses: codecov/codecov-action@v4
           with:
             files: ./backend/coverage.xml
             flags: python
   ```

3. **依存関係更新ワークフロー**:
   - `.github/dependabot.yml`:
   ```yaml
   version: 2
   updates:
     - package-ecosystem: "pub"
       directory: "/frontend/kotonoha_app"
       schedule:
         interval: "weekly"

     - package-ecosystem: "pip"
       directory: "/backend"
       schedule:
         interval: "weekly"

     - package-ecosystem: "github-actions"
       directory: "/"
       schedule:
         interval: "weekly"
   ```

4. **動作確認**:
   - GitHub上でワークフローが実行されることを確認
   - Pull Request作成時にチェックが走ることを確認

**完了条件**:
- [x] GitHub ActionsワークフローファイルがFlutter、Pythonそれぞれ存在する
- [x] ワークフローの構文エラーがない（YAMLとして正しい）
- [x] テストカバレッジが計測・アップロードされる設定
- [x] Lintチェックが実行される
- [x] Dependabotが設定されている

**テスト要件**: なし（DIRECT）

**実装記録**: `docs/implements/kotonoha/TASK-0019/`

---

### Day 20: プロジェクトドキュメント整備

#### TASK-0020: プロジェクトドキュメント整備・セットアップガイド作成
- [x] **タスク完了** (2025-11-22)

**推定工数**: 8時間

**タスクタイプ**: DIRECT

**要件名**: kotonoha

**関連要件**:
- NFR-205: ガイド付きアクセスの設定方法をアプリ内ヘルプで説明

**依存タスク**: TASK-0019

**実装詳細**:

1. **README.md更新**:
   - プロジェクトルート`README.md`を包括的に更新:
   ```markdown
   # kotonoha - 文字盤コミュニケーション支援アプリ

   ## 概要
   発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを目的としたタブレット向けコミュニケーション支援アプリ。

   ## 技術スタック
   - **フロントエンド**: Flutter 3.38.1
   - **バックエンド**: FastAPI 0.121
   - **データベース**: PostgreSQL 15
   - **状態管理**: Riverpod 2.x
   - **ローカルストレージ**: Hive

   ## セットアップ手順

   ### 前提条件
   - Docker & Docker Compose
   - Flutter SDK 3.38.1以上
   - Python 3.10以上

   ### 1. リポジトリクローン
   ```bash
   git clone https://github.com/mozuq-lab/kotonoha.git
   cd kotonoha
   ```

   ### 2. 環境変数設定
   ```bash
   cp .env.example .env
   # .envファイルを編集
   ```

   ### 3. Docker環境起動
   ```bash
   docker-compose up -d
   ```

   ### 4. データベースマイグレーション
   ```bash
   cd backend
   alembic upgrade head
   ```

   ### 5. Flutterアプリ起動
   ```bash
   cd frontend/kotonoha_app
   flutter pub get
   flutter run -d chrome
   ```

   ## 開発ガイド
   - [コントリビューションガイド](./CONTRIBUTING.md)
   - [API仕様書](http://localhost:8000/docs)
   - [アーキテクチャ設計](./docs/design/kotonoha/architecture.md)
   ```

2. **CONTRIBUTING.md作成**:
   - コーディング規約、プルリクエストの作成方法などを記載

3. **開発環境セットアップガイド作成**:
   - `docs/SETUP.md`:
   ```markdown
   # 開発環境セットアップガイド

   ## 目次
   1. Docker環境構築
   2. バックエンド開発環境
   3. フロントエンド開発環境
   4. トラブルシューティング

   ## 1. Docker環境構築
   （詳細手順）

   ## 2. バックエンド開発環境
   （Python仮想環境、Alembic、テスト実行など）

   ## 3. フロントエンド開発環境
   （Flutter SDK、コード生成、テスト実行など）

   ## 4. トラブルシューティング
   （よくある問題と解決策）
   ```

4. **APIドキュメント生成確認**:
   - FastAPIのSwagger UIが正常に表示されることを確認
   - http://localhost:8000/docs

5. **変更履歴作成**:
   - `CHANGELOG.md`作成:
   ```markdown
   # Changelog

   ## [Unreleased]

   ## [0.1.0] - 2025-11-19
   ### Added
   - 開発環境構築（Docker、PostgreSQL、FastAPI、Flutter）
   - データベースマイグレーション（Alembic）
   - Flutter基盤（Riverpod、Hive、go_router）
   - 共通UIコンポーネント
   - CI/CDパイプライン（GitHub Actions）
   ```

**完了条件**:
- [x] README.mdが包括的に更新されている
- [x] CONTRIBUTING.mdが存在する
- [x] docs/SETUP.mdが存在し、セットアップ手順が明確に記載されている
- [x] CHANGELOG.mdが存在する
- [x] APIドキュメント（Swagger UI）が正常に表示される

**テスト要件**: なし（DIRECT）

**実装記録**: `docs/implements/kotonoha/TASK-0020/`

---

## Phase 1 完了基準

### 必須条件
- [x] すべてのタスク（TASK-0001〜TASK-0020）が完了している
- [x] Docker環境でPostgreSQL、FastAPIが起動する
- [x] データベースマイグレーションが正常に実行される
- [x] Flutterアプリが起動し、基本的なナビゲーションが動作する
- [x] CI/CDパイプラインがGitHub Actionsで動作する
- [x] テストカバレッジが80%以上（可能な範囲で）

### 成果物チェックリスト
- [x] docker-compose.ymlが存在し、全サービスが起動する
- [x] database-schema.sqlが実装されている
- [x] Alembicマイグレーションファイルが存在する
- [x] Flutter基本構造（Riverpod、Hive、go_router）が動作する
- [x] 共通UIコンポーネント（ボタン、入力欄）が実装されている
- [x] README.md、SETUP.md、CONTRIBUTING.mdが存在する
- [x] GitHub Actionsワークフローが動作する

### 次フェーズへの引き継ぎ事項
- 環境変数の設定方法
- データベース接続情報
- CI/CDパイプラインの使用方法
- コーディング規約

---

## 関連ドキュメント

- [要件定義書](../../spec/kotonoha-requirements.md)
- [アーキテクチャ設計](../../design/kotonoha/architecture.md)
- [データベーススキーマ](../../design/kotonoha/database-schema.sql)
- [技術スタック定義](../../tech-stack.md)
- [タスク実装計画 - 全体概要](./kotonoha-overview.md)

---

## 更新履歴

- **2025-11-19**: Phase 1タスクファイル作成
- **2025-11-19**: タスク検証完了（tsumiki:kairo-task-verify により更新）
  - 信頼性レベルセクション追加
- **2025-11-22**: Phase 1完了
  - TASK-0020完了（プロジェクトドキュメント整備・セットアップガイド作成）
  - 全タスク（TASK-0001〜TASK-0020）完了
  - Phase 1完了基準をすべて達成
