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
- **Flutter**: 3.38.1 (2025年11月時点の最新安定版)
- **Dart**: 3.10+
- **対応プラットフォーム**: iOS / Android / Web

### 状態管理
- **Riverpod**: 2.x
  - コンパイル時の安全性
  - テスタビリティが高い
  - 非同期処理との親和性が高い
  - Providerの進化版

### UIライブラリ・デザイン
- **Material Design 3**: Flutter標準対応
- **Cupertino**: iOS風UIコンポーネント

### ルーティング
- **go_router**: 宣言的ルーティング、ディープリンク対応

### HTTP通信
- **dio**: 強力なHTTPクライアント、インターセプター対応
- **retrofit**: 型安全なAPI呼び出し（dioベース）

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
- **FastAPI**: 0.121+ (2025年11月時点の最新版)
- **Python**: 3.10+ (Pythonの安定版、Alembic要件を満たす)
- **Uvicorn**: ASGIサーバー（FastAPI標準）

### ORM・データベース接続
- **SQLAlchemy**: 2.x (最新版、async対応)
- **Alembic**: 1.17+ (データベースマイグレーションツール)
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

## 📁 推奨ディレクトリ構造

```
kotonoha/
├── mobile/                      # Flutter アプリケーション
│   ├── lib/
│   │   ├── main.dart           # エントリーポイント
│   │   ├── app.dart            # アプリルート
│   │   ├── features/           # 機能ごとのモジュール
│   │   │   ├── auth/           # 認証機能
│   │   │   │   ├── data/       # リポジトリ、データソース
│   │   │   │   ├── domain/     # エンティティ、ユースケース
│   │   │   │   └── presentation/  # UI、状態管理
│   │   │   └── home/           # ホーム機能
│   │   ├── core/               # 共通機能
│   │   │   ├── network/        # API クライアント
│   │   │   ├── storage/        # ローカルストレージ
│   │   │   ├── router/         # ルーティング
│   │   │   └── constants/      # 定数
│   │   ├── shared/             # 共有ウィジェット・ユーティリティ
│   │   │   ├── widgets/        # 再利用可能ウィジェット
│   │   │   └── utils/          # ヘルパー関数
│   │   └── gen/                # 自動生成ファイル
│   ├── test/                   # テストファイル
│   ├── integration_test/       # 統合テスト
│   ├── assets/                 # 画像、フォント等
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   └── README.md
│
├── backend/                     # FastAPI バックエンド
│   ├── app/
│   │   ├── main.py             # FastAPIアプリエントリーポイント
│   │   ├── api/                # APIエンドポイント
│   │   │   ├── v1/             # APIバージョニング
│   │   │   │   ├── endpoints/  # 各エンドポイント
│   │   │   │   │   ├── auth.py
│   │   │   │   │   └── users.py
│   │   │   │   └── api.py      # ルーター統合
│   │   │   └── deps.py         # 依存性注入
│   │   ├── core/               # コア機能
│   │   │   ├── config.py       # 設定管理
│   │   │   ├── security.py     # 認証・セキュリティ
│   │   │   └── database.py     # DB接続設定
│   │   ├── models/             # SQLAlchemy モデル
│   │   ├── schemas/            # Pydantic スキーマ
│   │   ├── crud/               # CRUD操作
│   │   ├── services/           # ビジネスロジック
│   │   └── utils/              # ユーティリティ
│   ├── alembic/                # データベースマイグレーション
│   │   ├── versions/           # マイグレーションファイル
│   │   └── env.py
│   ├── tests/                  # テストファイル
│   │   ├── conftest.py         # pytest設定
│   │   ├── test_api/           # APIテスト
│   │   └── test_services/      # サービステスト
│   ├── requirements.txt        # Python依存関係
│   ├── requirements-dev.txt    # 開発用依存関係
│   ├── .env.example            # 環境変数サンプル
│   ├── pyproject.toml          # Ruff/Black設定
│   └── README.md
│
├── docs/                        # プロジェクトドキュメント
│   ├── tech-stack.md           # このファイル
│   ├── api-design.md           # API設計書（将来作成）
│   └── architecture.md         # アーキテクチャ設計（将来作成）
│
├── docker-compose.yml           # 開発環境Docker設定
├── .gitignore
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
git clone <repository-url>
cd kotonoha

# 環境変数設定（バックエンド）
cd backend
cp .env.example .env
# .env ファイルを編集（DB接続情報等）
cd ..
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
cd mobile

# Flutter バージョン確認（FVM使用の場合）
fvm use 3.38.1  # またはインストール済みの最新安定版

# 依存関係インストール
flutter pub get

# コード生成（必要に応じて）
flutter pub run build_runner build --delete-conflicting-outputs

# iOS シミュレーター起動（macOS）
open -a Simulator
flutter run

# Android エミュレーター起動
flutter emulators --launch <emulator_id>
flutter run

# Web で起動
flutter run -d chrome
```

### 5. テスト実行

#### バックエンドテスト
```bash
cd backend
pytest                    # 全テスト実行
pytest --cov=app         # カバレッジ測定
pytest tests/test_api/   # 特定のテストのみ
```

#### フロントエンドテスト
```bash
cd mobile
flutter test                      # 単体テスト
flutter test --coverage          # カバレッジ測定
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
