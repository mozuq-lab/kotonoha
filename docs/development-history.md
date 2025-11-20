# 開発履歴

このファイルには、プロジェクトの過去の開発タスクの詳細な実装記録が含まれています。
最新の開発状況については [README.md](../README.md) を参照してください。

## Phase 1: 開発環境構築・基盤実装

### TASK-0001: Gitリポジトリ初期設定

- **完了日**: 2025-11-19
- **概要**: プロジェクトの基盤となるGitリポジトリの初期設定とディレクトリ構造の構築
- **実装内容**:
  - Gitリポジトリ初期化（mainブランチ作成、初回コミット完了）
  - プロジェクトディレクトリ構造作成（backend/, frontend/, docker/, .github/）
  - README.md作成（プロジェクト概要、セットアップ手順、技術スタック）
  - .gitignore作成（Python/Flutter開発環境対応）
  - .gitattributes作成（改行コード統一設定）
  - .env.example作成（環境変数テンプレート、全16項目）
  - LICENSE作成（MIT License）
- **成果物**:
  - ディレクトリ構造: 8ディレクトリ作成
  - ドキュメント: README.md (9,534 bytes), .env.example (853 bytes)
  - 設定ファイル: .gitattributes (382 bytes), LICENSE (1,073 bytes)
  - 実装記録: docs/implements/kotonoha/TASK-0001/ (setup-report.md, verify-report.md)

### TASK-0002: PostgreSQL Docker環境構築

- **完了日**: 2025-11-20
- **概要**: PostgreSQL 15+のDocker環境構築と初期化スクリプト作成
- **実装内容**:
  - PostgreSQL 15 Alpine Dockerfileの作成
  - 初期化スクリプト（init.sql）の実装
    - タイムゾーン設定（Asia/Tokyo）
    - 拡張機能有効化（uuid-ossp, pg_trgm）
    - スキーマバージョン管理テーブル（schema_info）の作成
  - docker-compose.yml作成（PostgreSQLサービス定義）
    - 環境変数からの設定読み込み
    - データ永続化ボリューム設定
    - ヘルスチェック機能組み込み（10秒間隔）
  - .envファイル作成（.env.exampleからコピー）
- **動作確認**:
  - Docker Desktopの起動確認
  - PostgreSQLコンテナのビルド・起動成功
  - データベース接続確認（psql経由）
  - 拡張機能インストール確認（uuid-ossp, pg_trgm）
  - schema_infoテーブル作成・初期データ挿入確認
  - ヘルスチェック成功（STATUS: healthy）
- **成果物**:
  - Dockerリソース:
    - イメージ: kotonoha-postgres:latest
    - コンテナ: kotonoha_postgres (STATUS: healthy)
    - ネットワーク: kotonoha_kotonoha_network
    - ボリューム: kotonoha_postgres_data
  - データベースリソース:
    - データベース: kotonoha_db
    - ユーザー: kotonoha_user
    - 拡張機能: uuid-ossp (1.1), pg_trgm (1.6)
    - テーブル: schema_info
  - ファイル:
    - docker/postgres/Dockerfile
    - docker/postgres/init.sql
    - docker-compose.yml
    - .env (環境変数設定)
  - 実装記録: docs/implements/kotonoha/TASK-0002/ (setup-report.md, verification-report.md)
- **接続情報**:

  ```bash
  # Docker内部からの接続
  docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db

  # ホストマシンからの接続
  psql -h localhost -p 5432 -U kotonoha_user -d kotonoha_db

  # DATABASE_URL
  postgresql://kotonoha_user:your_password@localhost:5432/kotonoha_db
  ```

### TASK-0006: データベーススキーマ設計・SQL作成

- **完了日**: 2025-11-20
- **概要**: PostgreSQLデータベーススキーマの設計と実装、ERD作成、SQL構文検証
- **実装内容**:
  - database-schema.sqlの構文修正（PostgreSQL 15準拠）
    - CREATE TABLE内のINDEX句を外部に移動（構文エラー解消）
    - ai_conversion_logs テーブル: AI変換ログ（プライバシー保護のためSHA-256ハッシュ化）
    - error_logs テーブル: システムエラーログ（デバッグ・監視用）
  - ERD（Entity Relationship Diagram）作成（Mermaid形式）
  - テーブル詳細説明書の作成
  - データ保持ポリシーの定義（AI変換ログ90日、エラーログ30日）
  - インデックス設計（created_at降順、error_code検索用）
- **動作確認**:
  - PostgreSQL 15.15での構文検証成功
  - トランザクション内でのテーブル作成・ロールバック確認
  - 全SQL文の実行成功（CREATE EXTENSION, CREATE FUNCTION, CREATE TABLE, CREATE INDEX, COMMENT）
- **成果物**:
  - データベーススキーマ:
    - テーブル: ai_conversion_logs, error_logs
    - インデックス: idx_ai_conversion_logs_created_at, idx_error_logs_code_created, idx_error_logs_created_at
    - 拡張機能: uuid-ossp（UUID生成）
    - 関数: update_updated_at_column（タイムスタンプ自動更新）
  - ファイル:
    - docs/design/kotonoha/database-schema.sql (9.8KB)
    - docs/design/kotonoha/database-erd.md (6.1KB)
  - 実装記録: docs/implements/kotonoha/TASK-0006/ (setup-report.md, verify-report.md)
- **データベーススキーマ概要**:
  ```sql
  -- ai_conversion_logs: AI変換ログテーブル
  --   - プライバシー保護のため入力/出力テキストはSHA-256ハッシュ化
  --   - 統計用に文字数、処理時間、丁寧さレベルを記録
  --   - NFR-002監視用（平均3秒以内）: processing_time_ms カラム

  -- error_logs: エラーログテーブル
  --   - システムエラー、APIエラーの記録用
  --   - JSONB型でコンテキスト情報を柔軟に保存
  --   - デバッグと監視用途
  ```
- **次のステップ**: TASK-0008（SQLAlchemyモデル実装）

### TASK-0007: Alembic初期設定・マイグレーション環境構築

- **完了日**: 2025-11-20
- **概要**: Alembic初期化、環境変数対応設定、データベースマイグレーション環境構築
- **実装内容**:
  - Alembic初期化（`alembic init alembic`）
    - backend/alembic/ディレクトリ生成
    - backend/alembic/versions/（マイグレーションファイル格納用）
    - backend/alembic/env.py（マイグレーション実行スクリプト）
    - backend/alembic.ini（設定ファイル）
  - バックエンドディレクトリ構造作成
    - backend/app/core/（コア機能：設定、セキュリティ等）
    - backend/app/db/（データベース関連）
    - backend/app/models/（SQLAlchemyモデル）
    - backend/app/schemas/（Pydanticスキーマ）
  - 設定ファイル作成
    - backend/app/core/config.py（Pydantic Settings使用）
      - 環境変数からの自動読み込み
      - 型安全な設定管理
      - DATABASE_URL自動生成（同期・非同期両対応）
    - backend/app/core/__init__.py
  - alembic.ini設定
    - 環境変数からの設定読み込み（コメント明記）
    - Ruff自動フォーマット有効化（post-write hook）
  - alembic/env.py設定
    - app.core.configから設定を読み込み
    - DATABASE_URL_SYNC使用（同期URL、Alembic対応）
    - 将来的なモデル追加に備えた構造（target_metadata = None）
  - 環境変数ファイル作成（backend/.env）
- **動作確認**:
  - PostgreSQLコンテナ確認（kotonoha_postgres: Up 9 hours (healthy)）
  - PostgreSQL接続確認（PostgreSQL 15.15）
  - Alembic動作確認（`alembic current`成功）
  - 設定モジュールインポート確認（app.core.config正常読み込み）
  - Python構文チェック成功（ast.parse検証）
- **成果物**:
  - Alembicリソース:
    - backend/alembic/（ディレクトリ）
    - backend/alembic/versions/（空、マイグレーション格納用）
    - backend/alembic/env.py（環境変数対応設定）
    - backend/alembic.ini（Ruff hook有効化）
  - 設定ファイル:
    - backend/app/core/__init__.py
    - backend/app/core/config.py（Pydantic Settings、型安全設定）
    - backend/.env（環境変数）
  - ディレクトリ:
    - backend/app/db/（空）
    - backend/app/models/（空）
    - backend/app/schemas/（空）
  - Pythonファイル数: 4ファイル
  - 実装記録: docs/implements/kotonoha/TASK-0007/ (setup-report.md, verify-report.md)
- **品質確認**:
  - [x] Python構文エラー: なし
  - [x] 環境変数読み込み: 正常
  - [x] PostgreSQL接続: 成功
  - [x] Alembicコマンド: 正常動作
  - [x] 型ヒント使用: 適切
  - [x] セキュリティ設定: 適切（.envはgitignore）
- **設定モジュール機能**:
  ```python
  # backend/app/core/config.py
  from app.core.config import settings

  # データベースURL（非同期）
  settings.DATABASE_URL
  # => postgresql+asyncpg://user:pass@localhost:5432/kotonoha_db

  # データベースURL（同期、Alembic用）
  settings.DATABASE_URL_SYNC
  # => postgresql://user:pass@localhost:5432/kotonoha_db

  # CORS許可オリジン（リスト）
  settings.CORS_ORIGINS_LIST
  # => ['http://localhost:3000', 'http://localhost:5173']
  ```
- **次のステップ**: TASK-0008（SQLAlchemyモデル実装）

### TASK-0008: SQLAlchemyモデル実装

- **完了日**: 2025-11-20
- **概要**: ai_conversion_logs と error_logs テーブルに対応する SQLAlchemy モデルの実装
- **実装内容**:
  - SQLAlchemy Base クラス定義（backend/app/db/base.py）
    - declarative_base を使用した基底クラス作成
    - カスタム __repr__ メソッドで読みやすいデバッグ出力
  - AIConversionLog モデル実装（backend/app/models/ai_conversion_log.py）
    - UUID 主キー（自動生成）
    - SHA-256 ハッシュフィールド（入力/出力テキスト）
    - 統計用フィールド（文字数、処理時間、丁寧さレベル）
    - created_at インデックス（降順）
  - ErrorLog モデル実装（backend/app/models/error_log.py）
    - UUID 主キー（自動生成）
    - error_code、error_message フィールド
    - JSONB 型 context フィールド（柔軟なコンテキスト保存）
    - 複合インデックス（error_code + created_at）
    - created_at インデックス（降順）
  - モデルインポート設定（backend/app/models/__init__.py）
    - 全モデルを一箇所でインポート可能に
  - Alembic 統合設定（backend/alembic/env.py）
    - target_metadata を Base.metadata に設定
    - 自動マイグレーション生成対応

詳細な実装記録は [docs/implements/kotonoha/TASK-0008/](implements/kotonoha/TASK-0008/) を参照してください。
