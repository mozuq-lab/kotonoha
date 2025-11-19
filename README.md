# kotonoha - 文字盤コミュニケーション支援アプリ

## プロジェクト概要

**kotonoha（ことのは）** は、発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを目的としたタブレット向けコミュニケーション支援アプリケーションです。

### 対象ユーザー

脳梗塞・ALS・筋疾患などで発話が困難だが、タブレットのタップ操作がある程度可能な方々

### 主な機能

- 文字盤入力による文章作成
- 定型文の登録・利用
- 大型ボタンによる簡単操作
- 緊急時ボタン（すぐに助けを呼べる）
- OS標準TTSによる読み上げ
- 入力履歴の保存・参照
- お気に入り機能
- AI変換機能（カジュアル/丁寧語への自動変換）
- アクセシビリティ対応（フォントサイズ調整、高コントラストモード）

## 技術スタック

- **フロントエンド**: Flutter 3.38.1 + Riverpod 2.x
- **バックエンド**: FastAPI 0.121 + SQLAlchemy 2.x + PostgreSQL 15+
- **開発環境**: Docker + Docker Compose
- **状態管理**: Riverpod
- **ローカルストレージ**: Hive
- **ルーティング**: go_router
- **TTS**: OS標準音声合成

詳細は [docs/tech-stack.md](docs/tech-stack.md) を参照してください。

## アーキテクチャの特徴

### オフラインファースト設計

- 基本機能はすべてオフラインで動作（文字盤入力、定型文、履歴、TTS読み上げ）
- AI変換のみオンライン必須、オフライン時は無効化
- ユーザーデータは端末内ローカル保存（Hive使用）
- プライバシー重視: クラウド同期なし、単一端末完結

### パフォーマンス要件

- TTS読み上げ開始: 1秒以内
- 文字盤タップ応答: 100ms以内
- AI変換応答: 平均3秒以内

### アクセシビリティ要件

- タップターゲットサイズ: 最小44px × 44px、推奨60px × 60px
- フォントサイズ: 小/中/大の3段階
- テーマ: ライト/ダーク/高コントラストの3種類
- 高コントラストモード: WCAG 2.1 AAレベル（コントラスト比4.5:1以上）

## セットアップ手順

### 前提条件

- Docker Desktop インストール済み
- Flutter SDK 3.38.1以上 インストール済み
- Python 3.10以上 インストール済み
- Git インストール済み

### 1. リポジトリクローン・初期設定

```bash
# リポジトリクローン
git clone <repository-url>
cd kotonoha

# 環境変数設定
cp .env.example .env
# .env ファイルを編集（DB接続情報、API Key等）
```

### 2. Docker環境起動

```bash
# PostgreSQL等のサービスを起動
docker-compose up -d

# ログ確認
docker-compose logs -f
```

### 3. バックエンド（FastAPI）セットアップ

```bash
cd backend

# 仮想環境作成
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 依存関係インストール
pip install -r requirements.txt

# データベースマイグレーション
alembic upgrade head

# 開発サーバー起動
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

ブラウザで確認:
- http://localhost:8000/docs (Swagger UI)
- http://localhost:8000/redoc (ReDoc)

### 4. フロントエンド（Flutter）セットアップ

```bash
cd frontend/kotonoha_app

# 依存関係インストール
flutter pub get

# コード生成（Riverpod, Hive等）
flutter pub run build_runner build --delete-conflicting-outputs

# Webで起動
flutter run -d chrome

# iOS シミュレーター起動（macOS）
open -a Simulator
flutter run

# Android エミュレーター起動
flutter emulators --launch <emulator_id>
flutter run
```

### 5. テスト実行

#### バックエンドテスト

```bash
cd backend
pytest                    # 全テスト実行
pytest --cov=app         # カバレッジ測定
```

#### フロントエンドテスト

```bash
cd frontend/kotonoha_app
flutter test                      # 単体テスト
flutter test --coverage          # カバレッジ測定
```

## 開発コマンド

### Docker

```bash
docker-compose up -d              # サービス起動
docker-compose down               # サービス停止
docker-compose logs -f <service>  # ログ確認
docker-compose ps                 # 実行中のサービス確認
```

### Flutter

```bash
flutter run                       # アプリ起動
flutter build apk                 # Android APKビルド
flutter build ios                 # iOS ビルド
flutter build web                 # Web ビルド
flutter test                      # テスト実行
flutter analyze                   # 静的解析
flutter clean                     # ビルドキャッシュクリア
```

### FastAPI

```bash
uvicorn app.main:app --reload     # 開発サーバー起動
alembic revision --autogenerate -m "message"  # マイグレーション作成
alembic upgrade head              # マイグレーション適用
pytest                            # テスト実行
ruff check .                      # リントチェック
ruff format .                     # コード整形
```

## 環境変数

`.env.example` をコピーして `.env` を作成し、以下の環境変数を設定してください:

- `POSTGRES_USER`: PostgreSQLユーザー名
- `POSTGRES_PASSWORD`: PostgreSQLパスワード
- `POSTGRES_DB`: データベース名
- `POSTGRES_HOST`: データベースホスト（デフォルト: localhost）
- `POSTGRES_PORT`: データベースポート（デフォルト: 5432）
- `SECRET_KEY`: JWT認証用シークレットキー（ランダムな文字列）
- `OPENAI_API_KEY`: OpenAI APIキー（AI変換機能用、オプション）

## ディレクトリ構造

```
kotonoha/
├── backend/                     # FastAPI バックエンド
│   ├── app/
│   │   ├── main.py             # FastAPIエントリーポイント
│   │   ├── api/                # APIエンドポイント
│   │   ├── core/               # コア機能（設定、セキュリティ、DB接続）
│   │   ├── models/             # SQLAlchemy モデル
│   │   ├── schemas/            # Pydantic スキーマ
│   │   ├── crud/               # CRUD操作
│   │   └── services/           # ビジネスロジック
│   ├── alembic/                # データベースマイグレーション
│   ├── tests/                  # テストファイル
│   └── requirements.txt        # Python依存関係
├── frontend/                    # Flutter フロントエンド
│   └── kotonoha_app/
│       ├── lib/
│       │   ├── main.dart       # エントリーポイント
│       │   ├── features/       # 機能ごとのモジュール
│       │   ├── core/           # 共通機能
│       │   └── shared/         # 共有ウィジェット・ユーティリティ
│       └── test/               # テストファイル
├── docs/                        # ドキュメント
│   ├── tech-stack.md           # 技術スタック定義
│   ├── spec/                   # 要件定義（EARS記法）
│   ├── design/                 # 技術設計
│   └── tasks/                  # タスク管理
├── docker/                      # Docker設定
│   ├── backend/
│   └── postgres/
├── .github/                     # GitHub Actions CI/CD
│   └── workflows/
└── docker-compose.yml           # 開発環境Docker設定
```

## 開発ワークフロー

### Tsumiki開発フレームワーク

このプロジェクトは **Tsumiki** (https://github.com/classmethod/tsumiki) を使用して開発されています。

主要なコマンド:

- `/tsumiki:kairo-requirements` - EARS記法による要件定義書作成
- `/tsumiki:kairo-design` - 技術設計文書生成
- `/tsumiki:kairo-tasks` - 実装タスク分割
- `/tsumiki:kairo-implement` - タスク実装
- `/tsumiki:tdd-red` - 失敗するテスト作成
- `/tsumiki:tdd-green` - テストを通す実装
- `/tsumiki:tdd-refactor` - リファクタリング

詳細は [CLAUDE.md](CLAUDE.md) を参照してください。

## ライセンス

MIT License

Copyright (c) 2025 kotonoha project

詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 参考資料

### プロジェクト内ドキュメント

- [技術スタック・セットアップ](docs/tech-stack.md)
- [要件定義書](docs/spec/kotonoha-requirements.md)
- [アーキテクチャ設計](docs/design/kotonoha/architecture.md)
- [データフロー図](docs/design/kotonoha/dataflow.md)
- [API仕様](docs/design/kotonoha/api-endpoints.md)
- [タスク管理](docs/tasks/kotonoha-overview.md)

### 外部リンク

- [Tsumiki Manual](https://github.com/classmethod/tsumiki/blob/main/MANUAL.md)
- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [FastAPI公式ドキュメント](https://fastapi.tiangolo.com/)
- [Riverpod公式ドキュメント](https://riverpod.dev/)

## 開発状況

### Phase 1: 開発環境構築・基盤実装

#### 完了したタスク

##### TASK-0001: Gitリポジトリ初期設定
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

##### TASK-0002: PostgreSQL Docker環境構築

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

## コントリビューション

コントリビューションを歓迎します。詳細は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## 問い合わせ

プロジェクトに関するお問い合わせは、Issue を作成してください。
