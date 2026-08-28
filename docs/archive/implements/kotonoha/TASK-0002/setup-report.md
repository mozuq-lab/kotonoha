# TASK-0002 設定作業実行報告

## 作業概要

- **タスクID**: TASK-0002
- **タスク名**: PostgreSQL Docker環境構築
- **タスクタイプ**: DIRECT
- **作業内容**: PostgreSQL 15+のDocker環境構築、初期化スクリプト作成、docker-compose.yml設定
- **実行日時**: 2025-11-20
- **実行者**: Claude (Tsumiki direct-setup)

## 設計文書参照

- **参照文書**:
  - `docs/tech-stack.md` - 技術スタック定義
  - `docs/design/kotonoha/architecture.md` - アーキテクチャ設計
  - `docs/design/kotonoha/database-schema.sql` - データベーススキーマ
  - `docs/tasks/kotonoha-phase1.md` - Phase 1タスク定義
- **関連要件**:
  - NFR-104: HTTPS通信、API通信を暗号化
  - NFR-105: 環境変数をアプリ内にハードコードせず、安全に管理

## 実行した作業

### 1. PostgreSQL Dockerfileの作成

**作成ファイル**: `docker/postgres/Dockerfile`

```dockerfile
# PostgreSQL 15+ Dockerfile for kotonoha project
FROM postgres:15-alpine

# Set environment variables
ENV POSTGRES_DB=kotonoha_db
ENV POSTGRES_USER=kotonoha_user
ENV LANG=ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8

# Copy initialization scripts
COPY init.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} || exit 1
```

**実装内容**:
- PostgreSQL 15 Alpine版を使用（軽量かつ最新安定版）
- 日本語ロケール設定（ja_JP.UTF-8）
- 初期化スクリプトの自動実行設定
- ヘルスチェック機能の組み込み（10秒間隔でDB接続確認）

### 2. PostgreSQL初期化スクリプトの作成

**作成ファイル**: `docker/postgres/init.sql`

```sql
-- PostgreSQL Initialization Script for kotonoha project
-- This script is executed when the PostgreSQL container is first created

-- Create database (if not exists)
-- Note: The database is already created via POSTGRES_DB environment variable
-- This is a placeholder for future initialization needs

-- Set timezone
SET timezone = 'Asia/Tokyo';

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search optimization

-- Create schema version table for tracking migrations
-- Note: Alembic will manage migrations, but this provides a basic schema info table
CREATE TABLE IF NOT EXISTS schema_info (
    version VARCHAR(50) PRIMARY KEY,
    description TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial schema version
INSERT INTO schema_info (version, description)
VALUES ('0.0.0', 'Initial database setup')
ON CONFLICT (version) DO NOTHING;

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'kotonoha database initialization completed successfully';
END $$;
```

**実装内容**:
- タイムゾーンを日本標準時（Asia/Tokyo）に設定
- UUID生成用拡張機能（uuid-ossp）の有効化
- テキスト検索最適化用拡張機能（pg_trgm）の有効化
- スキーマバージョン管理テーブルの作成
- 初期化完了ログの出力

### 3. docker-compose.ymlの作成

**作成ファイル**: `docker-compose.yml`

```yaml
version: '3.8'

services:
  postgres:
    build: ./docker/postgres
    container_name: kotonoha_postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-kotonoha_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-your_secure_password}
      POSTGRES_DB: ${POSTGRES_DB:-kotonoha_db}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./docker/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - kotonoha_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-kotonoha_user} -d ${POSTGRES_DB:-kotonoha_db}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
    driver: local

networks:
  kotonoha_network:
    driver: bridge
```

**実装内容**:
- PostgreSQLサービスの定義
- 環境変数からの設定読み込み（デフォルト値付き）
- データ永続化用ボリューム設定
- 初期化スクリプトの自動マウント
- ネットワーク設定（kotonoha_network）
- 自動再起動設定（unless-stopped）
- ヘルスチェック機能の組み込み

### 4. 環境変数設定の確認

**確認ファイル**: `.env.example`

既存の`.env.example`に以下のPostgreSQL設定が含まれていることを確認:

```env
# データベース設定
POSTGRES_USER=kotonoha_user
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=kotonoha_db
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
```

**確認内容**:
- データベースユーザー名: `kotonoha_user`
- データベース名: `kotonoha_db`
- ポート番号: `5432`（PostgreSQL標準ポート）
- パスワードはプレースホルダーとして設定済み（実際の運用時は変更必須）

### 5. Docker環境の検証

```bash
# Docker バージョン確認
docker --version
# Docker version 28.3.2, build 578ccf6

# Docker Compose バージョン確認
docker compose version
# Docker Compose version v2.39.1-desktop.1
```

**検証内容**:
- Docker Desktop がインストールされている
- Docker Compose v2が利用可能
- ディレクトリ構造が正しく作成されている:
  - `docker/postgres/Dockerfile`
  - `docker/postgres/init.sql`
  - `docker-compose.yml`

## 作業結果

- [x] PostgreSQL Dockerfileの作成完了
- [x] 初期化スクリプト（init.sql）の作成完了
- [x] docker-compose.ymlの作成完了
- [x] 環境変数設定の確認完了（.env.exampleに既存）
- [x] Docker環境の検証完了

## 設定内容の詳細

### データベース設定
- **DBMS**: PostgreSQL 15+ (Alpine Linux版)
- **データベース名**: `kotonoha_db`
- **ユーザー名**: `kotonoha_user`
- **ポート**: 5432
- **文字コード**: UTF-8
- **ロケール**: ja_JP.UTF-8
- **タイムゾーン**: Asia/Tokyo

### 有効化した拡張機能
1. **uuid-ossp**: UUID生成機能（AI変換ログのID生成に使用）
2. **pg_trgm**: テキスト検索最適化（将来的な全文検索機能用）

### セキュリティ設定
- パスワードは環境変数から読み込み（.envファイルで管理、Gitには含めない）
- データはDockerボリュームで永続化（ホストファイルシステムへの直接アクセスを制限）
- 初期化スクリプトは読み取り専用でマウント

### ヘルスチェック
- 間隔: 10秒
- タイムアウト: 5秒
- リトライ回数: 5回
- コマンド: `pg_isready` (PostgreSQL標準のヘルスチェックコマンド)

## 遭遇した問題と解決方法

### 問題1: docker-composeコマンドが見つからない

- **発生状況**: `docker-compose --version`コマンド実行時
- **エラーメッセージ**: `command not found: docker-compose`
- **解決方法**: Docker Compose v2では`docker compose`（スペース区切り）に変更されているため、新しいコマンド構文を使用
- **対応**: docker-compose.ymlは両バージョンで互換性があるため、ファイル自体の修正は不要

## 次のステップ

1. **Docker環境の起動テスト**:
   ```bash
   # .envファイルの作成（.env.exampleをコピー）
   cp .env.example .env

   # パスワードを適切に設定（.envファイルを編集）

   # PostgreSQLコンテナの起動
   docker compose up -d postgres

   # ログ確認
   docker compose logs -f postgres

   # ヘルスチェック確認
   docker compose ps
   ```

2. **データベース接続確認**:
   ```bash
   # PostgreSQLコンテナ内でpsqlを実行
   docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db

   # 拡張機能確認
   \dx

   # スキーマ確認
   \dt

   # schema_infoテーブル確認
   SELECT * FROM schema_info;
   ```

3. **次タスク（TASK-0003）の準備**:
   - FastAPI Docker環境構築
   - バックエンドサービスをdocker-compose.ymlに追加
   - PostgreSQLとバックエンドの連携確認

4. **動作確認コマンド（/tsumiki:direct-verify）の実行**:
   - PostgreSQLコンテナの起動確認
   - データベース接続テスト
   - 初期化スクリプトの実行確認
   - ヘルスチェックの動作確認

## 参考情報

### 使用したDockerイメージ
- **postgres:15-alpine**: 公式PostgreSQL Alpine Linux版（軽量・セキュア）

### ディレクトリ構造
```
kotonoha/
├── docker/
│   ├── postgres/
│   │   ├── Dockerfile          # 作成済み
│   │   └── init.sql            # 作成済み
│   └── backend/                # 次タスクで作成予定
├── docker-compose.yml          # 作成済み
└── .env.example                # 既存（確認済み）
```

### 関連ドキュメント
- [PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/15/)
- [Docker Compose公式ドキュメント](https://docs.docker.com/compose/)
- `docs/tech-stack.md`: 技術スタック定義
- `docs/design/kotonoha/database-schema.sql`: データベーススキーマ定義

---

**作業完了日時**: 2025-11-20
**次アクション**: `/tsumiki:direct-verify`コマンドを実行してセットアップの動作確認を行う
