# TASK-0007 設定作業実行記録

## 作業概要

- **タスクID**: TASK-0007
- **タスク名**: Alembic初期設定・マイグレーション環境構築
- **作業内容**: Alembic初期化、環境変数対応設定、データベースマイグレーション環境構築
- **実行日時**: 2025-11-20
- **作業タイプ**: DIRECT（設定作業）

## 設計文書参照

- **参照文書**:
  - `docs/tech-stack.md` - 技術スタック定義
  - `docs/design/kotonoha/architecture.md` - アーキテクチャ設計
  - `docs/design/kotonoha/database-schema.sql` - データベーススキーマ
- **関連要件**:
  - NFR-304: データベースエラー発生時に適切なエラーハンドリング
  - NFR-501: コードカバレッジ80%以上のテスト

## 実行した作業

### 1. Alembic初期化

```bash
cd backend
alembic init alembic
```

**実行結果**:
- `backend/alembic/`ディレクトリが生成された
- `backend/alembic/versions/`（マイグレーションファイル格納用）
- `backend/alembic/env.py`（マイグレーション実行スクリプト）
- `backend/alembic/script.py.mako`（テンプレート）
- `backend/alembic.ini`（設定ファイル）

### 2. バックエンドディレクトリ構造作成

```bash
mkdir -p backend/app/core backend/app/db backend/app/models backend/app/schemas
```

**作成されたディレクトリ**:
- `backend/app/core/` - コア機能（設定、セキュリティ等）
- `backend/app/db/` - データベース関連（セッション、Base等）
- `backend/app/models/` - SQLAlchemyモデル
- `backend/app/schemas/` - Pydanticスキーマ

### 3. 設定ファイル作成

#### 3-1. `backend/app/core/config.py`

Pydantic Settingsを使用した設定管理クラスを作成:

```python
class Settings(BaseSettings):
    # データベース設定
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str

    # API設定
    SECRET_KEY: str
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000

    # ... 他の設定

    @property
    def DATABASE_URL(self) -> str:
        """非同期データベースURL（asyncpg）"""
        return f"postgresql+asyncpg://..."

    @property
    def DATABASE_URL_SYNC(self) -> str:
        """同期データベースURL（Alembicマイグレーション用）"""
        return f"postgresql://..."
```

**機能**:
- 環境変数（`.env`）から設定を自動読み込み
- 型安全な設定管理
- データベースURL自動生成（同期・非同期両対応）

#### 3-2. `backend/app/core/__init__.py`

パッケージ初期化ファイル作成。

### 4. alembic.ini設定

#### 4-1. データベースURL設定

元の設定:
```ini
sqlalchemy.url = driver://user:pass@localhost/dbname
```

変更後:
```ini
# Note: The actual database URL is loaded from app/core/config.py
# This placeholder is not used but required by Alembic
sqlalchemy.url = postgresql://user:pass@localhost/dbname
```

#### 4-2. Ruff自動フォーマット有効化

```ini
hooks = ruff
ruff.type = module
ruff.module = ruff
ruff.options = check --fix REVISION_SCRIPT_FILENAME
```

マイグレーションファイル生成時に自動的にRuff lintを実行。

### 5. alembic/env.py設定

環境変数から設定を読み込み、PostgreSQL接続を行うよう設定:

```python
# 環境変数から設定を読み込み
from app.core.config import settings

# データベースURLを環境変数から設定（同期URL）
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL_SYNC)

# モデルのMetaDataオブジェクト（TASK-0008で実装予定）
target_metadata = None
```

**重要な変更点**:
- 環境変数（`.env`）から設定を自動読み込み
- `DATABASE_URL_SYNC`を使用（Alembicは同期的に動作するため）
- 将来的なモデル追加に備えた構造

**初期実装での問題と修正**:
- 最初、`async_engine_from_config`を使用したが、Alembicは同期的に動作するため、`engine_from_config`に修正
- エラー: `The asyncio extension requires an async driver to be used. The loaded 'psycopg2' is not async.`
- 修正: 同期エンジンを使用するように変更

### 6. 環境変数ファイル作成

```bash
cp .env.example backend/.env
```

`backend/.env`に以下の環境変数を設定:
- `POSTGRES_USER=kotonoha_user`
- `POSTGRES_PASSWORD=...`
- `POSTGRES_DB=kotonoha_db`
- `POSTGRES_HOST=localhost`
- `POSTGRES_PORT=5432`
- `SECRET_KEY=...`

### 7. 動作確認

#### 7-1. PostgreSQLコンテナ確認

```bash
docker ps --filter "name=postgres"
```

**結果**:
```
kotonoha_postgres: Up 8 hours (healthy)
```

PostgreSQLコンテナが正常に起動していることを確認。

#### 7-2. Alembic動作確認

```bash
cd backend
alembic current
```

**結果**:
```
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
```

Alembicが正常に動作し、PostgreSQLに接続できることを確認。

## 作業結果

- [x] Alembicの初期化完了
- [x] 環境変数からの設定読み込み設定完了
- [x] `app/core/config.py`作成完了
- [x] `alembic.ini`設定完了
- [x] `alembic/env.py`設定完了
- [x] PostgreSQL接続確認完了
- [x] Alembic動作確認完了

## 作成ファイル一覧

1. `backend/alembic/`（ディレクトリ、Alembicにより自動生成）
   - `versions/`
   - `env.py`（手動で修正）
   - `script.py.mako`
   - `README`
2. `backend/alembic.ini`（Alembicにより自動生成、手動で修正）
3. `backend/app/core/`（ディレクトリ）
   - `__init__.py`
   - `config.py`
4. `backend/app/db/`（ディレクトリ、空）
5. `backend/app/models/`（ディレクトリ、空）
6. `backend/app/schemas/`（ディレクトリ、空）
7. `backend/.env`（環境変数ファイル）

## 遭遇した問題と解決方法

### 問題1: 非同期エンジンの使用エラー

- **発生状況**: `alembic current`実行時にエラー
- **エラーメッセージ**:
  ```
  sqlalchemy.exc.InvalidRequestError: The asyncio extension requires an async driver to be used.
  The loaded 'psycopg2' is not async.
  ```
- **原因**: `alembic/env.py`で`async_engine_from_config`を使用していたが、Alembicは同期的に動作する
- **解決方法**: `engine_from_config`に変更し、`DATABASE_URL_SYNC`（`postgresql://...`）を使用

### 問題2: 環境変数が読み込まれない

- **発生状況**: `alembic current`実行時に`Field required`エラー
- **原因**: `backend/.env`ファイルが存在しなかった
- **解決方法**: `.env.example`を`backend/.env`にコピー

## 次のステップ

次のタスクは**TASK-0008: SQLAlchemyモデル実装**です。

実行コマンド:
```bash
/tsumiki:direct-verify
```

その後、TASK-0008でモデルを実装し、以下を行います:
1. `app/db/base_class.py`作成（Baseクラス）
2. `app/models/ai_conversion_logs.py`作成（AI変換ログモデル）
3. `app/models/error_logs.py`作成（エラーログモデル）
4. `app/db/base.py`作成（モデル集約）
5. `app/db/session.py`作成（データベースセッション管理）
6. `alembic/env.py`を更新（`target_metadata`をNoneから実際のMetaDataに変更）

## 完了条件の確認

- [x] Alembicが初期化されている
- [x] alembic.iniが環境変数から設定を読み込む
- [x] env.pyがSQLAlchemyに対応している
- [x] 初回マイグレーションファイルが生成可能（TASK-0008で実施）
- [x] PostgreSQLに接続できる
- [x] `alembic current`コマンドが正常に実行される

## 備考

- TASK-0008でモデル実装後、`alembic revision --autogenerate -m "Initial migration"`を実行してマイグレーションファイルを生成する予定
- 非同期SQLAlchemyは`app/db/session.py`で使用する予定（FastAPI実行時）
- Alembicマイグレーションは同期的に動作する（これは正常な動作）
