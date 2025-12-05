# kotonoha - 文字盤コミュニケーション支援アプリ

[![Flutter CI](https://github.com/yourusername/kotonoha/actions/workflows/flutter.yml/badge.svg)](https://github.com/yourusername/kotonoha/actions/workflows/flutter.yml)
[![Python CI](https://github.com/yourusername/kotonoha/actions/workflows/python.yml/badge.svg)](https://github.com/yourusername/kotonoha/actions/workflows/python.yml)

## 概要

**kotonoha（ことのは）** は、発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを目的としたタブレット向けコミュニケーション支援アプリケーションです。

このリポジトリには、メインアプリケーションに加えて、connpassイベント通知システムも含まれています。

### 対象ユーザー

脳梗塞・ALS・筋疾患などで発話が困難だが、タブレットのタップ操作がある程度可能な方々

### 主な機能

- **文字盤入力**: かな/英数文字盤による文章作成
- **定型文機能**: よく使うフレーズの登録・利用
- **大型ボタン**: 視認性が高く押しやすいサイズ設計
- **緊急ボタン**: すぐに助けを呼べる機能
- **音声読み上げ**: OS標準TTSによる読み上げ
- **入力履歴**: 過去の入力内容の保存・参照
- **お気に入り**: よく使う文章の保存
- **AI変換**: カジュアル/丁寧語への自動変換（オンライン機能）
- **アクセシビリティ**: フォントサイズ調整、高コントラストモード対応

## 技術スタック

| カテゴリ | 技術 | バージョン |
|---------|------|-----------|
| フロントエンド | Flutter | 3.38.1 |
| 状態管理 | Riverpod | 2.x |
| ローカルストレージ | Hive | 2.x |
| ルーティング | go_router | 14.x |
| バックエンド | FastAPI | 0.121+ |
| ORM | SQLAlchemy | 2.x |
| データベース | PostgreSQL | 15+ |
| マイグレーション | Alembic | 1.17+ |
| コンテナ | Docker + Docker Compose | 最新版 |

## アーキテクチャの特徴

### オフラインファースト設計

- 基本機能はすべてオフラインで動作（文字盤入力、定型文、履歴、TTS読み上げ）
- AI変換のみオンライン必須、オフライン時は無効化
- ユーザーデータは端末内ローカル保存（Hive使用）
- プライバシー重視: クラウド同期なし、単一端末完結

### パフォーマンス要件

| 項目 | 目標値 |
|------|--------|
| TTS読み上げ開始 | 1秒以内 |
| 文字盤タップ応答 | 100ms以内 |
| AI変換応答 | 平均3秒以内 |

### アクセシビリティ要件

- タップターゲットサイズ: 最小44px x 44px、推奨60px x 60px
- フォントサイズ: 小/中/大の3段階
- テーマ: ライト/ダーク/高コントラストの3種類
- 高コントラストモード: WCAG 2.1 AAレベル（コントラスト比4.5:1以上）

## クイックスタート

### 前提条件

- Docker Desktop インストール済み
- Flutter SDK 3.38.1以上 インストール済み
- Python 3.10以上 インストール済み
- Git インストール済み

### 1. リポジトリクローン

```bash
git clone <repository-url>
cd kotonoha
```

### 2. 環境変数設定

```bash
cp .env.example .env
# .env ファイルを編集（DB接続情報、SECRET_KEY等）
```

### 3. Docker環境起動

```bash
docker-compose up -d
```

### 4. バックエンドセットアップ

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

ブラウザで確認:
- http://localhost:8000/docs (Swagger UI)
- http://localhost:8000/health (ヘルスチェック)

### 5. フロントエンドセットアップ

```bash
cd frontend/kotonoha_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

詳細なセットアップ手順は [docs/SETUP.md](docs/SETUP.md) を参照してください。

## プロジェクト構造

```
kotonoha/
├── backend/                     # FastAPI バックエンド
│   ├── app/
│   │   ├── main.py             # FastAPIエントリーポイント
│   │   ├── api/                # APIエンドポイント
│   │   ├── core/               # コア機能（設定、セキュリティ、DB接続）
│   │   ├── models/             # SQLAlchemy モデル
│   │   ├── schemas/            # Pydantic スキーマ
│   │   └── db/                 # データベース関連
│   ├── alembic/                # データベースマイグレーション
│   └── tests/                  # テストファイル
├── frontend/                    # Flutter フロントエンド
│   └── kotonoha_app/
│       ├── lib/
│       │   ├── main.dart       # エントリーポイント
│       │   ├── app.dart        # アプリルート
│       │   ├── core/           # 共通機能（テーマ、ルーター、ユーティリティ）
│       │   ├── features/       # 機能ごとのモジュール
│       │   └── shared/         # 共有ウィジェット・モデル
│       └── test/               # テストファイル
├── docker/                      # Docker設定
│   ├── backend/                # バックエンドDockerfile
│   └── postgres/               # PostgreSQL設定
├── connpass-notifier/           # Connpassイベント通知システム（AWS SAM）
│   ├── functions/              # Lambda関数
│   ├── tests/                  # テストファイル
│   ├── template.yaml           # SAMテンプレート
│   └── README.md               # 詳細ドキュメント
├── docs/                        # ドキュメント
│   ├── tech-stack.md           # 技術スタック定義
│   ├── SETUP.md                # セットアップガイド
│   ├── spec/                   # 要件定義（EARS記法）
│   ├── design/                 # 技術設計
│   └── tasks/                  # タスク管理
├── .github/                     # GitHub Actions CI/CD
│   └── workflows/
├── docker-compose.yml           # 開発環境Docker設定
├── CONTRIBUTING.md              # コントリビューションガイド
├── CHANGELOG.md                 # 変更履歴
└── CLAUDE.md                    # Claude Code用ガイド
```

## 開発コマンド

### Docker

```bash
docker-compose up -d              # サービス起動
docker-compose down               # サービス停止
docker-compose logs -f postgres   # ログ確認
```

### バックエンド（FastAPI）

```bash
cd backend
uvicorn app.main:app --reload     # 開発サーバー起動
pytest                            # テスト実行
pytest --cov=app                  # カバレッジ測定
ruff check .                      # Lintチェック
ruff format .                     # コード整形
alembic upgrade head              # マイグレーション適用
alembic revision --autogenerate -m "message"  # マイグレーション作成
```

### フロントエンド（Flutter）

```bash
cd frontend/kotonoha_app
flutter run                       # アプリ起動
flutter run -d chrome             # Webで起動
flutter test                      # テスト実行
flutter test --coverage           # カバレッジ測定
flutter analyze                   # 静的解析
flutter pub run build_runner build --delete-conflicting-outputs  # コード生成
```

## テスト

### バックエンド

```bash
cd backend
pytest                    # 全テスト実行
pytest --cov=app         # カバレッジ測定
pytest tests/test_api/   # 特定のテストのみ
```

### フロントエンド

```bash
cd frontend/kotonoha_app
flutter test                      # 単体テスト
flutter test --coverage          # カバレッジ測定
```

## 環境変数

`.env.example` をコピーして `.env` を作成し、以下の環境変数を設定してください:

| 変数名 | 説明 | デフォルト値 |
|--------|------|-------------|
| `POSTGRES_USER` | PostgreSQLユーザー名 | - |
| `POSTGRES_PASSWORD` | PostgreSQLパスワード | - |
| `POSTGRES_DB` | データベース名 | - |
| `POSTGRES_HOST` | データベースホスト | localhost |
| `POSTGRES_PORT` | データベースポート | 5432 |
| `SECRET_KEY` | JWT認証用シークレットキー | - |
| `OPENAI_API_KEY` | OpenAI APIキー（オプション） | - |
| `ENVIRONMENT` | 環境設定 | development |

## CI/CD

### GitHub Actions

プロジェクトでは以下のCI/CDワークフローが設定されています:

#### Flutter CI (`.github/workflows/flutter.yml`)
- **トリガー**: `main`, `develop` ブランチへの push/PR
- **実行内容**:
  - 依存関係インストール・コード生成
  - 静的解析 (`flutter analyze`)
  - フォーマットチェック (`dart format`)
  - テスト実行・カバレッジ測定
  - Web/APK ビルド・アーティファクト保存

#### Python CI (`.github/workflows/python.yml`)
- **トリガー**: `main`, `develop` ブランチへの push/PR
- **実行内容**:
  - Lint チェック (`ruff check`, `black --check`)
  - PostgreSQL サービスコンテナでテスト実行
  - マイグレーション実行
  - pytest によるテスト・カバレッジ測定
  - セキュリティ監査 (`pip-audit`)

#### Dependabot (`.github/dependabot.yml`)
- Flutter/Dart、Python、GitHub Actions の依存関係を週次で自動更新

## 開発ワークフロー

### Tsumiki開発フレームワーク

このプロジェクトは **[Tsumiki](https://github.com/classmethod/tsumiki)** を使用して開発されています。

主要なコマンド:
- `/tsumiki:kairo-requirements` - EARS記法による要件定義書作成
- `/tsumiki:kairo-design` - 技術設計文書生成
- `/tsumiki:kairo-tasks` - 実装タスク分割
- `/tsumiki:kairo-implement` - タスク実装
- `/tsumiki:tdd-red` - 失敗するテスト作成
- `/tsumiki:tdd-green` - テストを通す実装
- `/tsumiki:tdd-refactor` - リファクタリング

### Git ブランチ戦略

- **main**: 本番環境ブランチ
- **develop**: 開発統合ブランチ
- **feature/xxx**: 機能開発ブランチ
- **fix/xxx**: バグ修正ブランチ

## 開発状況

### Phase 1: 開発環境構築・基盤実装 (完了)

**期間**: 2025-11-19 〜 2025-11-22

**完了タスク**:
- TASK-0001〜0005: プロジェクト初期設定・Docker環境構築
- TASK-0006〜0010: データベース設計・マイグレーション・基本API実装
- TASK-0011〜0015: Flutterプロジェクト構造構築（Riverpod、Hive、go_router）
- TASK-0016〜0020: 共通コンポーネント・ユーティリティ・CI/CD・ドキュメント整備

**成果物**:
- Docker開発環境（PostgreSQL、FastAPI）
- データベーススキーマ・Alembicマイグレーション
- Flutter基盤（Riverpod状態管理、Hiveストレージ、go_routerナビゲーション）
- テーマ実装（ライト/ダーク/高コントラスト）
- 共通UIコンポーネント（LargeButton、TextInputField、EmergencyButton）
- ユーティリティ関数（Logger、バリデーション、エラーハンドリング）
- CI/CDパイプライン（GitHub Actions）

### Phase 2: バックエンドAPI実装 (完了)

**期間**: 2025-11-22

**完了タスク**:
- TASK-0021〜0022: FastAPI基盤構築・ヘルスチェックAPI
- TASK-0023〜0024: Pydanticスキーマ定義・AI変換ログテーブル実装
- TASK-0025: レート制限ミドルウェア実装
- TASK-0026〜0028: 外部AI API連携・AI変換エンドポイント実装
- TASK-0029〜0031: エラーハンドリング・ロギング・グローバル例外処理

**成果物**:
- AI変換API（POST /api/v1/ai/convert、POST /api/v1/ai/regenerate）
- ヘルスチェックAPI（GET /api/v1/health）
- レート制限（1分間10リクエスト）
- AI変換ログテーブル（プライバシー対応ハッシュ化）
- エラーログテーブル・グローバル例外ハンドラー
- Swagger UI API文書
- pytestテストスイート（90%以上カバレッジ）

### Phase 3: フロントエンド基本機能実装 (完了)

**期間**: 2025-11-22 〜 2025-11-27

**完了タスク**:
- TASK-0037〜0039: 五十音文字盤UI、文字入力バッファ管理、削除・全消去ボタン
- TASK-0040〜0042: 定型文一覧UI、CRUD機能、初期データ（87個サンプル）
- TASK-0043〜0044: 「はい」「いいえ」「わからない」大ボタン、状態ボタン（12種類）
- TASK-0045〜0047: 緊急ボタンUI、2段階確認、緊急音実装
- TASK-0048〜0051: TTS読み上げ機能（OS連携、速度設定、中断機能）
- TASK-0052〜0053: 対面表示モード、180度回転機能
- TASK-0054〜0060: ローカルストレージ（Hive）、状態管理、統合テスト

**成果物**:
- 五十音文字盤（あ〜ん、濁音、半濁音、拗音、100ms応答）
- 文字入力バッファ（1000文字制限、削除・全消去機能）
- 定型文機能（一覧表示、CRUD、カテゴリ分類、お気に入り）
- 大ボタン（「はい」「いいえ」「わからない」即時読み上げ）
- 状態ボタン（「痛い」「トイレ」等12種類）
- 緊急ボタン（2段階確認、緊急音再生）
- TTS読み上げ（OS標準TTS、速度調整、1秒以内開始）
- 対面表示モード（180度回転表示）
- Hiveローカルストレージ（オフラインデータ永続化）

### Phase 4: フロントエンド応用機能実装 (完了)

**期間**: 2025-11-27 〜 2025-11-29

**完了タスク**:
- TASK-0061〜0063: 履歴一覧UI、履歴CRUD機能、履歴Provider状態管理
- TASK-0064〜0066: お気に入りUI、お気に入りCRUD、Provider実装
- TASK-0067〜0070: AI変換UI、ローディング表示、結果表示・選択UI、Provider実装
- TASK-0071〜0074: 設定画面UI、フォントサイズ設定、テーマ設定、TTS速度設定
- TASK-0075: ヘルプ画面・初回チュートリアル実装
- TASK-0076〜0077: ネットワーク状態Provider、オフラインUI表示
- TASK-0078〜0079: エラーUI・メッセージ、アプリ状態復元・クラッシュリカバリ
- TASK-0080: Phase 4 統合テスト

**成果物**:
- 履歴管理機能（一覧表示、検索、削除、タップで再利用）
- お気に入り機能（追加・削除、一覧表示、並び替え）
- AI変換連携UI（丁寧さレベル選択、ローディング表示、結果選択）
- 設定画面（フォントサイズ小/中/大、テーマ3種、TTS速度調整、AI丁寧さレベル）
- ヘルプ画面・初回チュートリアル（5ステップガイド）
- オフライン対応（ネットワーク状態監視、オフラインバナー、AI変換無効化）
- エラーUI（日本語エラーメッセージ、再試行オプション）
- アプリ状態復元（バックグラウンド復帰時の入力テキスト・ルート復元）
- 1340テストケース（カバレッジ80%以上）

## ドキュメント

### プロジェクト内ドキュメント

- [技術スタック・セットアップ](docs/tech-stack.md)
- [開発環境セットアップガイド](docs/SETUP.md)
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

## コントリビューション

コントリビューションを歓迎します。詳細は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## 追加ツール

### Connpass Event Notifier

このリポジトリには、connpassの参加予定イベントを監視し、開催前にメール通知を送るAWS SAMアプリケーションが含まれています。

**主な機能:**
- 定期的にconnpassアカウントページをチェック
- 参加予定イベントをDynamoDBに保存
- イベント開始前（デフォルト24時間前）にメール通知
- AWS Lambda + EventBridge + SESによるサーバーレス実装

**セットアップ:**
```bash
cd connpass-notifier
sam build
sam deploy --guided
```

詳細は [connpass-notifier/README.md](connpass-notifier/README.md) および [connpass-notifier/DEPLOYMENT.md](connpass-notifier/DEPLOYMENT.md) を参照してください。

## ライセンス

MIT License

Copyright (c) 2025 kotonoha project

詳細は [LICENSE](LICENSE) ファイルを参照してください。

## 問い合わせ

プロジェクトに関するお問い合わせは、Issue を作成してください。
