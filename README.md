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

### Phase 1: 開発環境構築・基盤実装（進行中）

#### 最新の完了タスク

- **TASK-0011**: Flutterプロジェクトディレクトリ構造設計・実装（完了日: 2025-11-20）
  - Clean Architecture準拠のディレクトリ構造作成（24個のディレクトリ）
  - アクセシビリティ対応の定数ファイル実装（app_colors.dart、app_sizes.dart、app_text_styles.dart）
  - Material Design 3テーマ実装（ライト/ダーク/高コントラスト）
  - WCAG 2.1 AA準拠の高コントラストテーマ（コントラスト比21:1）
  - 17ファイル作成、1251行追加

#### Phase 1 進捗サマリー（Week 1-3: Day 1-11）

**Week 1: プロジェクト初期設定・Docker環境構築 ✅**
- [x] TASK-0001: Gitリポジトリ初期設定
- [x] TASK-0002: PostgreSQL Docker環境構築
- [x] TASK-0003: FastAPI Docker環境構築
- [x] TASK-0004: Python開発環境設定
- [x] TASK-0005: Flutter開発環境セットアップ

**Week 2: データベース設計・マイグレーション ✅**
- [x] TASK-0006: データベーススキーマ設計・SQL作成
- [x] TASK-0007: Alembic初期設定・マイグレーション環境構築
- [x] TASK-0008: SQLAlchemyモデル実装
- [x] TASK-0009: 初回マイグレーション実行・DB接続テスト（TDD: 21テストケース全通過）
- [x] TASK-0010: バックエンドヘルスチェック・基本APIエンドポイント実装（TDD: 17テストケース全通過）

**Week 3: Flutter プロジェクト構造構築（進行中）**
- [x] TASK-0011: Flutterプロジェクトディレクトリ構造設計・実装
- [x] TASK-0012: Flutter依存パッケージ追加・pubspec.yaml設定（完了日: 2025-11-20）
- [ ] TASK-0013: Riverpod状態管理セットアップ・プロバイダー基盤実装
- [ ] TASK-0014: Hiveローカルストレージセットアップ・データモデル実装
- [ ] TASK-0015: go_routerナビゲーション設定・ルーティング実装

**Week 4: 共通コンポーネント・ユーティリティ実装（未着手）**
- [ ] TASK-0016〜TASK-0020: 実装予定

#### 詳細な実装記録

各タスクの詳細な実装内容、動作確認結果、成果物については以下を参照してください:

- **過去の完了タスク**: [docs/development-history.md](docs/development-history.md)
- **個別タスク実装記録**: docs/implements/kotonoha/TASK-XXXX/

## コントリビューション

コントリビューションを歓迎します。詳細は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## 問い合わせ

プロジェクトに関するお問い合わせは、Issue を作成してください。
