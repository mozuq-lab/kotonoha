# プロジェクト技術スタック定義

## 🔧 生成情報
- **生成日**: 2025-11-19
- **生成ツール**: tsumiki:init-tech-stack
- **プロジェクトタイプ**: ハイブリッドアプリ（Flutter - iOS/Android/Web対応）
- **チーム規模**: 個人開発
- **開発期間**: プロトタイプ/MVP（1-2ヶ月）

## 🎯 プロジェクト要件サマリー
- **パフォーマンス**: 軽負荷（同時利用者数10人以下、レスポンス時間3秒以内）
- **セキュリティ**: 基本的なWebセキュリティ対策
- **技術スキル**: JavaScript/TypeScript、Python、データベース設計経験豊富
- **学習コスト許容度**: 積極的に新技術を導入したい
- **デプロイ先**: クラウド（AWS/Azure/GCP）
- **予算**: バランス重視（適度なコストは許容）
- **既存システム連携**: なし（新規構築）

## 🚀 フロントエンド（モバイル・Web）

### フレームワーク・言語
- **Flutter**: 3.38.1 (CI/CDのピン留めバージョン。`.github/workflows/*.yml` の `FLUTTER_VERSION`)
- **Dart**: 3.10（Flutter 3.38.1 同梱。`pubspec.lock` の解決下限は 3.9.0、`pubspec.yaml` の宣言は `>=3.5.0 <4.0.0`）
- **対応プラットフォーム**: iOS / Android / Web

### 状態管理
- **Riverpod**: 3.x（`flutter_riverpod: ^3.1.0`、2026-07-19時点。当初はRiverpod 2.xを想定していたが、実装は3.xに移行済み）
  - コンパイル時の安全性
  - テスタビリティが高い
  - 非同期処理との親和性が高い
  - Providerの進化版

### UIライブラリ・デザイン
- **Material Design 3**: Flutter標準対応
- **Cupertino**: iOS風UIコンポーネント

### ルーティング
- **go_router**: 17.x（`go_router: ^17.0.1`）宣言的ルーティング、ディープリンク対応

### HTTP通信
- **dio**: 強力なHTTPクライアント、インターセプター対応

### ローカルストレージ
- **shared_preferences**: シンプルなkey-value保存
- **hive** または **isar**: ローカルデータベース（必要に応じて）

### 選択理由
- 1コードベースでiOS/Android/Web対応、開発効率が非常に高い
- Hot Reloadで高速な開発サイクル
- ネイティブに近いパフォーマンス
- Material Design 3で現代的なUI/UX
- JavaScript/TypeScript経験者ならDartの習得が容易
- 豊富なパッケージエコシステム（pub.dev）

## ⚙️ バックエンド

### フレームワーク・言語
- **FastAPI**: 0.124+ (`backend/requirements.txt` は `fastapi==0.124.0` を固定)
- **Python**: 3.10+ (Pythonの安定版、Alembic要件を満たす)
- **Uvicorn**: ASGIサーバー（FastAPI標準）

### ORM・データベース接続
- **SQLAlchemy**: 2.x (最新版、async対応)
- **Alembic**: 1.18+ (データベースマイグレーションツール。`alembic==1.18.3` を固定)
- **asyncpg**: 非同期PostgreSQLドライバ

### 認証・セキュリティ
- **JWT (JSON Web Token)**: トークンベース認証
- **OAuth2 + Bearer Token**: FastAPI標準の認証方式
- **passlib + bcrypt**: パスワードハッシュ化
- **python-jose**: JWT生成・検証

### バリデーション
- **Pydantic**: 2.x (FastAPI標準、データバリデーション・型安全性)

### CORS設定
- **FastAPI CORS middleware**: クロスオリジン設定

### 選択理由
- あなたのPython経験を最大限活用できる
- 非同期対応で高速（Node.js/Go並みのパフォーマンス）
- 自動APIドキュメント生成（Swagger UI / ReDoc）
- Pydanticで型安全性を確保
- SQLAlchemyでリレーショナルDBの強力な操作が可能
- MVP開発に最適な学習コスト
- 将来の拡張性が高い

## 💾 データベース

### メインデータベース
- **PostgreSQL**: 15+ (最新安定版)
  - ACID準拠のトランザクション
  - JSONB型でNoSQL的な柔軟性も確保
  - あなたのデータベース設計経験を活かせる
  - 高度なインデックス戦略
  - 将来のスケーリングに対応

### キャッシュ（オプション）
- **Redis**: 7+ (必要に応じて)
  - セッション管理
  - 高速キャッシュ
  - リアルタイム機能のPub/Sub

### ファイルストレージ
- **開発環境**: ローカルファイルシステム
- **本番環境**: AWS S3 / Azure Blob Storage / Google Cloud Storage

### 設計方針
- 適切な正規化レベル（第3正規形を基本）
- インデックス戦略でクエリ最適化
- 外部キー制約でデータ整合性を保証
- Alembicでマイグレーション管理

## 🛠️ 開発環境・ツール

### コンテナ化
- **Docker**: 最新安定版
- **Docker Compose**: 開発環境の一貫性確保
  - PostgreSQL
  - Redis（オプション）
  - FastAPI
  - Flutter Web（必要に応じて）

### パッケージマネージャー
- **Frontend (Flutter)**: pub (Flutter標準)
- **Backend (Python)**: pip + venv または Poetry

### バージョン管理
- **Git**: バージョン管理
- **GitHub / GitLab**: リモートリポジトリ

### Flutter開発ツール
- **IDE**: VS Code / Android Studio
- **FVM (Flutter Version Management)**: Flutter バージョン管理
- **flutter_lints**: 公式推奨リンター
- **dart format**: コード整形

### Python開発ツール
- **IDE**: VS Code / PyCharm
- **Ruff**: 高速リンター（Flake8/Black/isort代替）
- **Black**: コードフォーマッター（またはRuff format）
- **mypy**: 型チェック（オプション）

### テストツール

#### Flutter
- **flutter_test**: 単体テスト・Widgetテスト
- **integration_test**: 統合テスト・E2Eテスト
- **mockito** / **mocktail**: モック・スタブ

#### Python (FastAPI)
- **pytest**: テストフレームワーク
- **pytest-asyncio**: 非同期テスト対応
- **httpx**: 非同期HTTPクライアント（テスト用）
- **pytest-cov**: カバレッジ測定

### CI/CD
- **GitHub Actions**: 自動テスト・ビルド・デプロイ
  - Flutterテスト実行
  - Pythonテスト実行
  - コードカバレッジ測定
  - Lintチェック
  - 自動デプロイ（本番・ステージング）

### APIドキュメント
- **Swagger UI**: FastAPIが自動生成（/docs）
- **ReDoc**: 代替APIドキュメント（/redoc）

## ☁️ インフラ・デプロイ

### IaC（Infrastructure as Code）
- **AWS CDK**: 2.x (TypeScript)
  - インフラをコードで管理
  - バージョン管理・レビュー可能
  - 型安全なインフラ定義
  - CloudFormationによる確実なデプロイ

**管理対象リソース**:
- VPC、サブネット、セキュリティグループ
- ECS/Fargate クラスター（バックエンドAPI）
- RDS for PostgreSQL
- S3バケット（ログ、将来的なファイルストレージ）
- CloudWatch（監視・ログ）
- Secrets Manager（環境変数・認証情報）
- ALB（Application Load Balancer）

**選択理由**:
- TypeScript経験を活かせる
- AWSリソースの一元管理
- 開発/ステージング/本番環境の構成を統一
- インフラ変更の履歴管理とロールバックが容易

### モバイルアプリ配布
- **iOS**:
  - 開発: Xcode + Simulator
  - テスト配布: TestFlight
  - 本番: App Store
- **Android**:
  - 開発: Android Studio + Emulator
  - テスト配布: Google Play Console (Internal Testing)
  - 本番: Google Play

### Webアプリ（Flutter Web）
- **ホスティング**: Vercel / Netlify
  - 無料枠から開始可能
  - 自動CDN配信
  - HTTPSデフォルト

### バックエンドAPI（FastAPI）
- **コンテナ実行環境（推奨）**:
  - AWS ECS (Fargate) / AWS App Runner
  - Google Cloud Run
  - Azure Container Apps
- **代替案**:
  - Heroku（簡単デプロイ、個人開発に最適）
  - Railway / Render（モダンなPaaS）

### データベース
- **マネージドサービス（推奨）**:
  - AWS RDS for PostgreSQL
  - Google Cloud SQL for PostgreSQL
  - Azure Database for PostgreSQL
- **接続**: SSL/TLS必須、接続プーリング設定

### 環境分離
- **開発環境**: ローカル（Docker Compose）
- **ステージング環境**: クラウド（本番と同じ構成）
- **本番環境**: クラウド

## 🔒 セキュリティ

### 通信セキュリティ
- **HTTPS**: 必須（証明書自動更新）
- **TLS 1.2+**: 暗号化通信

### 認証・認可
- **JWT**: アクセストークン（短命、15分程度）
- **Refresh Token**: リフレッシュトークン（長命、7日程度）
- **OAuth2**: 標準的な認証フロー
- **Password Hashing**: bcrypt（コスト係数12以上）

### API セキュリティ
- **CORS**: 適切なオリジン設定
- **Rate Limiting**: API呼び出し回数制限（必要に応じて）
- **Input Validation**: Pydanticで厳密なバリデーション
- **SQL Injection対策**: SQLAlchemy ORMを使用
- **XSS対策**: 適切なエスケープ処理

### 環境変数管理
- **開発**: `.env` ファイル（Gitignore必須）
- **本番**: クラウドの環境変数機能を使用
  - AWS Secrets Manager / Parameter Store
  - Google Secret Manager
  - Azure Key Vault

### 依存関係セキュリティ
- **定期的な脆弱性チェック**:
  - Flutter: `dart pub outdated`, `flutter pub upgrade`
  - Python: `pip-audit`, Dependabot

## 📊 品質基準

### テストカバレッジ
- **目標**: 80%以上
- **重要な部分**: ビジネスロジック、APIエンドポイントは90%以上

### コード品質
- **Flutter**: flutter_lints準拠
- **Python**: Ruff + Black準拠、型ヒント使用

### 型安全性
- **Dart**: Null Safety有効
- **Python**: Pydantic使用、mypy推奨

### パフォーマンス
- **Flutter Web**: Lighthouse スコア 80+点
- **API レスポンス**: 平均500ms以内（軽負荷想定）

### アクセシビリティ
- **Flutter**: Semanticsウィジェット使用
- **WCAG 2.1 AA**: 基本的な準拠を目指す

## 📁 ディレクトリ構造

以下は**実際のリポジトリ構成**（2026-08-24 時点）。
初期生成時は `mobile/` + `infra/`（AWS CDK）を想定していたが、実装では Flutter アプリを
`frontend/kotonoha_app/` に置き、`infra/` は未作成（IaCはMVP範囲外のため未着手）。

```
kotonoha/
├── frontend/
│   └── kotonoha_app/            # Flutter アプリケーション
│       ├── lib/
│       │   ├── main.dart        # エントリーポイント
│       │   ├── app.dart         # アプリルート
│       │   ├── features/        # 機能ごとのモジュール
│       │   │   ├── character_board/   # 文字盤入力
│       │   │   ├── preset_phrase/     # 定型文
│       │   │   ├── tts/               # 音声読み上げ
│       │   │   ├── history/           # 入力履歴
│       │   │   ├── favorite/          # お気に入り
│       │   │   ├── emergency/         # 緊急ボタン
│       │   │   ├── ai_conversion/     # AI変換
│       │   │   ├── settings/          # 設定
│       │   │   └── ...                # 他、face_to_face / simple_mode 等
│       │   │       ├── data/          # 各featureの構成: リポジトリ、APIクライアント
│       │   │       ├── domain/        #                 エンティティ、例外
│       │   │       ├── presentation/  #                 UI（画面・ウィジェット）
│       │   │       └── providers/     #                 Riverpod プロバイダ
│       │   ├── core/            # 共通機能
│       │   │   ├── router/      # go_router 定義
│       │   │   ├── themes/      # テーマ（ライト/ダーク/高コントラスト）
│       │   │   ├── constants/   # 定数
│       │   │   ├── widgets/     # 共通ウィジェット
│       │   │   └── utils/       # ヘルパー関数
│       │   ├── shared/          # 共有モデル・プロバイダ・ウィジェット
│       │   └── l10n/            # 多言語化リソース（app_ja.arb）
│       ├── test/                # 単体・ウィジェットテスト
│       ├── integration_test/    # E2E/統合テスト
│       ├── test_driver/         # flutter drive 用ドライバ
│       ├── assets/              # 音声等のアセット
│       ├── pubspec.yaml
│       ├── analysis_options.yaml
│       └── README.md
│
├── backend/                     # FastAPI バックエンド
│   ├── app/
│   │   ├── main.py             # FastAPIアプリエントリーポイント
│   │   ├── api/                # APIエンドポイント
│   │   │   ├── v1/
│   │   │   │   ├── endpoints/  # ai.py（AI変換）、health.py
│   │   │   │   └── api.py      # ルーター統合
│   │   │   └── deps.py         # 依存性注入・APIキー認証
│   │   ├── core/               # コア機能
│   │   │   ├── config.py       # 設定管理（pydantic-settings）
│   │   │   ├── security.py     # APIキー検証
│   │   │   ├── rate_limit.py   # レート制限（slowapi）
│   │   │   ├── exceptions.py   # 例外定義
│   │   │   └── logging_config.py
│   │   ├── db/                 # DB接続設定・ベースクラス
│   │   ├── models/             # SQLAlchemy モデル
│   │   ├── schemas/            # Pydantic スキーマ
│   │   ├── crud/               # CRUD操作
│   │   └── utils/              # AIクライアント、ハッシュ等
│   ├── alembic/                # データベースマイグレーション
│   │   ├── versions/           # マイグレーションファイル
│   │   └── env.py
│   ├── tests/                  # テストファイル
│   │   ├── conftest.py         # pytest設定
│   │   ├── test_api/           # APIテスト
│   │   └── test_security/      # 認証テスト
│   ├── requirements.txt        # Python依存関係
│   ├── .env.example            # 環境変数サンプル（アプリ設定）
│   ├── pyproject.toml          # Ruff/Black/pytest設定
│   ├── Makefile
│   └── Dockerfile              # 本番用（マルチステージ・非root）
│
├── docker/                      # 開発環境用Docker設定
│   ├── backend/Dockerfile      # 開発用（--reload 有効）
│   └── postgres/               # Dockerfile + init.sql
│
├── scripts/                     # ビルドスクリプト
│   ├── build-web.sh
│   ├── build-android.sh
│   └── build-ios.sh
│
├── docs/                        # プロジェクトドキュメント
│   ├── tech-stack.md           # このファイル
│   ├── SETUP.md                # セットアップガイド
│   ├── spec/                   # 要件定義（EARS記法）
│   ├── design/                 # 技術設計
│   ├── tasks/                  # タスク管理
│   └── implements/             # TDD実施記録
│
├── .github/workflows/           # CI/CD（flutter.yml / python.yml / release.yml）
├── docker-compose.yml           # 開発環境Docker設定
├── .env.example                 # ルート環境変数サンプル（compose変数展開＋Flutterビルド）
├── .pre-commit-config.yaml
├── CONTRIBUTING.md
├── CHANGELOG.md
├── AGENTS.md                    # エージェント向け共通ガイド（正本）
├── CLAUDE.md                    # AGENTS.md を参照するだけ
└── README.md                    # プロジェクト概要
```

## 🚀 セットアップ手順

### 前提条件
- Docker Desktop インストール済み
- Flutter SDK インストール済み (FVM推奨)
- Python 3.10+ インストール済み
- Git インストール済み

### 1. リポジトリクローン・初期設定
```bash
# リポジトリクローン（既にある場合はスキップ）
git clone https://github.com/mozuq-lab/kotonoha.git
cd kotonoha

# 環境変数設定
# ルート .env: docker-compose の変数展開とFlutterビルド用
cp .env.example .env

# backend/.env: バックエンドのアプリ設定（AIキー・API_KEYS・レート制限等）
# compose の environment はこれより優先されるため、アプリ設定はこちらに書く
cp backend/.env.example backend/.env
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
pip install -r requirements-dev.txt

# データベースマイグレーション
alembic upgrade head

# 開発サーバー起動
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# ブラウザで確認
# http://localhost:8000/docs （Swagger UI）
# http://localhost:8000/redoc （ReDoc）
```

### 4. フロントエンド（Flutter）セットアップ
```bash
cd frontend/kotonoha_app

# Flutter バージョン確認（FVM使用の場合）
fvm use 3.38.1  # CI（.github/workflows/*.yml の FLUTTER_VERSION）と同じバージョン

# 依存関係インストール
flutter pub get

# ルート .env の API_BASE_URL / AI_API_KEY を --dart-define で渡す
# （Flutterは .env を直接読まないため、環境変数に展開して渡す）
# 未設定のキーはフォールバックで補う。空文字を渡すと defaultValue が打ち消されるため必須。
# ルート .env が未作成だと source が失敗する（set -e 環境では中断する）
set -a; source ../../.env; set +a
DEFINES=(--dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:8000}")
if [ -n "${AI_API_KEY:-}" ]; then
  DEFINES+=(--dart-define=AI_API_KEY="$AI_API_KEY")
fi

# iOS シミュレーター起動（macOS）
open -a Simulator
flutter run "${DEFINES[@]}"

# Android エミュレーター起動
flutter emulators --launch <emulator_id>
flutter run "${DEFINES[@]}"

# Web で起動
flutter run -d chrome "${DEFINES[@]}"
```

`--dart-define` を完全に省略した場合はアプリ側のデフォルト
（`API_BASE_URL=http://localhost:8000`、`AI_API_KEY` は空文字）が使われる。
ただし `--dart-define=API_BASE_URL=`（空文字）を渡すと `String.fromEnvironment` の
`defaultValue` が無効になり、`baseUrl` が空文字になってAI変換が失敗する（Dart 3.10.0 で実測確認）。
ルート `.env` に両キーが無い環境でも壊れないよう、必ず上記のフォールバック付きで組み立てること。

### 5. AWS CDKセットアップ（本番環境用）

> **未着手**: `infra/` ディレクトリはまだ存在しない（IaCはMVP範囲外）。
> 以下は将来の構成案であり、現時点では実行できない。

```bash
cd infra

# AWS CDK CLI インストール（未インストールの場合）
npm install -g aws-cdk

# 依存関係インストール
npm install

# AWS認証情報設定
aws configure  # アクセスキー、シークレットキー、リージョンを設定

# CDK環境初期化（初回のみ）
cdk bootstrap aws://<account-id>/<region>

# デプロイ前の差分確認
cdk diff

# デプロイ
cdk deploy --all  # すべてのスタックをデプロイ
```

### 6. テスト実行

#### バックエンドテスト
```bash
cd backend
pytest                    # 全テスト実行
pytest --cov=app         # カバレッジ測定
pytest tests/test_api/   # 特定のテストのみ
```

#### フロントエンドテスト
```bash
cd frontend/kotonoha_app
flutter test                      # 単体テスト
flutter test --coverage          # カバレッジ測定
# web は flutter drive 経由（integration_test/README.md 参照）
flutter test integration_test/   # 統合テスト
```

## 🔧 主要コマンド一覧

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
flutter pub outdated              # 依存関係の更新確認
flutter clean                     # ビルドキャッシュクリア
```

`flutter run` / `flutter build` に接続先・APIキーを渡すときは
`--dart-define=API_BASE_URL=... --dart-define=AI_API_KEY=...` を付ける
（空文字を渡さないこと。前述のフォールバックを参照）。

### ビルドスクリプト（--dart-define を自動付与・推奨）
```bash
# 環境変数 API_BASE_URL / AI_API_KEY を読み、未設定時のフォールバック込みで
# --dart-define を組み立てる（空文字は渡さない）
set -a; source .env; set +a         # リポジトリルートで実行
./scripts/build-web.sh release      # Web（debug/release/profile/serve/clean）
./scripts/build-android.sh release  # Android APK（bundle でAAB）
./scripts/build-ios.sh release      # iOS アプリのビルドのみ（IPAは --archive / --testflight で生成）
```

### FastAPI
```bash
uvicorn app.main:app --reload     # 開発サーバー起動
alembic revision --autogenerate -m "message"  # マイグレーション作成
alembic upgrade head              # マイグレーション適用
alembic downgrade -1              # マイグレーションロールバック
pytest                            # テスト実行
ruff check .                      # リントチェック
ruff format .                     # コード整形
```

### AWS CDK

```bash
cd infra
cdk bootstrap                     # 初回のみ: CDK環境初期化
cdk synth                         # CloudFormation テンプレート生成
cdk diff                          # 変更差分確認
cdk deploy --all                  # 全スタックデプロイ
cdk deploy NetworkStack           # 特定スタックのみデプロイ
cdk destroy --all                 # 全リソース削除（注意）
npm test                          # CDKスタックテスト実行
```

## 📝 開発ワークフロー

### 新機能開発の流れ
1. **要件定義**: 機能要件を明確化
2. **API設計**: バックエンドAPIエンドポイント設計
3. **DB設計**: 必要に応じてテーブル設計・マイグレーション作成
4. **バックエンド実装**: FastAPI エンドポイント実装
5. **バックエンドテスト**: pytestでテスト作成・実行
6. **フロントエンド実装**: Flutter UI・ロジック実装
7. **フロントエンドテスト**: flutter_test でテスト作成・実行
8. **統合テスト**: E2Eテスト実行
9. **コードレビュー**: Pull Request作成
10. **デプロイ**: CI/CDで自動デプロイ

### Git ブランチ戦略
- **main**: 本番環境ブランチ
- **develop**: 開発統合ブランチ
- **feature/xxx**: 機能開発ブランチ
- **fix/xxx**: バグ修正ブランチ

## 🎓 学習リソース

### Flutter
- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [Riverpod公式ドキュメント](https://riverpod.dev/)
- [pub.dev](https://pub.dev/) - Flutterパッケージリポジトリ

### FastAPI
- [FastAPI公式ドキュメント](https://fastapi.tiangolo.com/)
- [SQLAlchemy公式ドキュメント](https://docs.sqlalchemy.org/)
- [Pydantic公式ドキュメント](https://docs.pydantic.dev/)

### PostgreSQL
- [PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/)

## 🔄 更新履歴
- **2025-11-19**: 初回生成（tsumiki:init-tech-stack により自動生成）
  - Flutter 3.38.1 + Dart 3.10
  - FastAPI 0.121 + Python 3.10+
  - PostgreSQL 15+ + SQLAlchemy 2.x + Alembic 1.17+
  - Riverpod 2.x 状態管理
  - Docker開発環境
  - GitHub Actions CI/CD
- **2026-07-19**: 記述と実装の乖離を修正
  - 状態管理をRiverpod 2.x → 3.x（`flutter_riverpod: ^3.1.0`）に修正（pubspec.yaml確認）
- **2026-08-24**: 依存バージョン表記を実装と突き合わせて修正
  - FastAPI 0.121+ → 0.124+（`backend/requirements.txt`: `fastapi==0.124.0`）
  - Alembic 1.17+ → 1.18+（`backend/requirements.txt`: `alembic==1.18.3`）
  - go_router のバージョン（17.x）を明記（`pubspec.yaml`: `go_router: ^17.0.1`）
  - Dart の表記を「3.10（Flutter 3.38.1 同梱）」に統一（`bin/cache/dart-sdk/version` = 3.10.0 を確認。
    `pubspec.lock` の `sdks.dart: ">=3.9.0"` はロックを解決できる下限であって使用中の版ではない）

---

## 📌 次のステップ

このファイルを基に、以下のステップでプロジェクトを進めてください：

1. **環境構築**: 上記セットアップ手順に従って開発環境を構築
2. **Hello World**: Flutter + FastAPI の最小構成で動作確認
3. **要件定義**: `/tsumiki:kairo-requirements` で詳細な要件定義を作成
4. **設計**: `/tsumiki:kairo-design` で技術設計書を作成
5. **タスク分割**: `/tsumiki:kairo-tasks` で実装タスクを分割
6. **TDD開発**: `/tsumiki:tdd-*` コマンドでテスト駆動開発

このファイルはプロジェクトの進行に応じて随時更新してください。
