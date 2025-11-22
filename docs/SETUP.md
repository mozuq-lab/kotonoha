# 開発環境セットアップガイド

このドキュメントでは、kotonohaプロジェクトの開発環境を構築する手順を詳しく説明します。

## 目次

1. [前提条件](#前提条件)
2. [Docker環境構築](#docker環境構築)
3. [バックエンド開発環境](#バックエンド開発環境)
4. [フロントエンド開発環境](#フロントエンド開発環境)
5. [IDE設定](#ide設定)
6. [動作確認](#動作確認)
7. [トラブルシューティング](#トラブルシューティング)

## 前提条件

### 必要なソフトウェア

| ソフトウェア | バージョン | 確認コマンド |
|-------------|-----------|-------------|
| Git | 最新版 | `git --version` |
| Docker Desktop | 最新版 | `docker --version` |
| Docker Compose | 最新版 | `docker-compose --version` |
| Python | 3.10以上 | `python --version` |
| Flutter SDK | 3.38.1以上 | `flutter --version` |
| Dart SDK | 3.10以上 | `dart --version` |

### オプション

- **FVM (Flutter Version Management)**: 複数のFlutterバージョンを管理する場合
- **pyenv**: 複数のPythonバージョンを管理する場合

## Docker環境構築

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd kotonoha
```

### 2. 環境変数の設定

```bash
# 環境変数ファイルをコピー
cp .env.example .env
```

`.env` ファイルを編集して、必要な値を設定します:

```bash
# データベース設定
POSTGRES_USER=kotonoha_user
POSTGRES_PASSWORD=your_secure_password_here  # 安全なパスワードに変更
POSTGRES_DB=kotonoha_db
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# バックエンドAPI設定
SECRET_KEY=your_secret_key_here  # ランダムな文字列に変更
API_HOST=0.0.0.0
API_PORT=8000

# AI変換機能設定（オプション）
# OPENAI_API_KEY=sk-your-openai-api-key-here

# 環境設定
ENVIRONMENT=development
```

> **注意**: `SECRET_KEY` はセキュリティ上重要です。本番環境では十分にランダムな文字列を使用してください。
>
> 生成例: `python -c "import secrets; print(secrets.token_urlsafe(32))"`

### 3. Docker環境の起動

```bash
# 全サービスを起動（バックグラウンド）
docker-compose up -d

# ログを確認
docker-compose logs -f

# 特定のサービスのログを確認
docker-compose logs -f postgres
docker-compose logs -f backend
```

### 4. 起動確認

```bash
# 実行中のコンテナを確認
docker-compose ps

# PostgreSQLに接続確認
docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db -c "SELECT 1"
```

### Docker Compose サービス構成

| サービス名 | ポート | 説明 |
|-----------|--------|------|
| postgres | 5432 | PostgreSQLデータベース |
| backend | 8000 | FastAPI バックエンドAPI |

## バックエンド開発環境

### 1. Python仮想環境の作成

```bash
cd backend

# 仮想環境を作成
python -m venv venv

# 仮想環境を有効化
# macOS / Linux
source venv/bin/activate

# Windows
venv\Scripts\activate
```

### 2. 依存関係のインストール

```bash
# 必須パッケージ
pip install -r requirements.txt

# 開発用パッケージ（オプション）
pip install -r requirements-dev.txt  # 存在する場合
```

### 3. データベースマイグレーション

```bash
# マイグレーションを適用
alembic upgrade head

# マイグレーション状態を確認
alembic current
```

### 4. 開発サーバーの起動

```bash
# 開発サーバーを起動（ホットリロード有効）
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 5. APIドキュメントの確認

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **ヘルスチェック**: http://localhost:8000/health

### コマンド一覧

```bash
# 開発サーバー起動
uvicorn app.main:app --reload

# テスト実行
pytest

# カバレッジ付きテスト
pytest --cov=app --cov-report=html

# Lintチェック
ruff check app tests

# コード整形
ruff format app tests

# マイグレーション作成
alembic revision --autogenerate -m "説明"

# マイグレーション適用
alembic upgrade head

# マイグレーションロールバック
alembic downgrade -1
```

## フロントエンド開発環境

### 1. Flutter SDKの確認

```bash
# Flutter SDKバージョン確認
flutter --version

# 環境チェック
flutter doctor

# 必要に応じて問題を修正
flutter doctor -v
```

### 2. 依存関係のインストール

```bash
cd frontend/kotonoha_app

# パッケージをインストール
flutter pub get

# 依存関係の更新確認
flutter pub outdated
```

### 3. コード生成

Riverpod、Hive、JSON Serializableなどのコード生成:

```bash
# コード生成（一回実行）
flutter pub run build_runner build --delete-conflicting-outputs

# 監視モード（開発中に自動生成）
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. アプリの起動

```bash
# Web版で起動
flutter run -d chrome

# iOS シミュレーターで起動（macOS）
open -a Simulator
flutter run

# Android エミュレーターで起動
flutter emulators --launch <emulator_id>
flutter run

# 利用可能なデバイス一覧
flutter devices
```

### コマンド一覧

```bash
# アプリ起動
flutter run
flutter run -d chrome          # Web
flutter run -d <device_id>     # 特定のデバイス

# ビルド
flutter build apk              # Android APK
flutter build ios              # iOS
flutter build web              # Web

# テスト
flutter test                   # 全テスト
flutter test --coverage        # カバレッジ付き
flutter test test/unit/        # 特定ディレクトリ

# 静的解析
flutter analyze

# コード整形
dart format .

# パッケージ管理
flutter pub get                # 依存関係取得
flutter pub upgrade            # 依存関係更新
flutter pub outdated           # 更新可能なパッケージ確認

# クリーンアップ
flutter clean                  # ビルドキャッシュ削除
```

## IDE設定

### VS Code（推奨）

#### 推奨拡張機能

```json
// .vscode/extensions.json
{
  "recommendations": [
    "Dart-Code.dart-code",
    "Dart-Code.flutter",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "charliermarsh.ruff",
    "esbenp.prettier-vscode"
  ]
}
```

#### 設定

```json
// .vscode/settings.json
{
  // Python
  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true,
  "python.formatting.provider": "black",
  "python.testing.pytestEnabled": true,

  // Dart/Flutter
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.rulers": [80],
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": "off"
  },
  "dart.lineLength": 80,

  // 一般
  "editor.formatOnSave": true,
  "files.exclude": {
    "**/.dart_tool": true,
    "**/.idea": true,
    "**/build": true
  }
}
```

### Android Studio / IntelliJ IDEA

1. Flutter プラグインをインストール
2. Dart プラグインをインストール
3. Python プラグインをインストール
4. プロジェクトを開く

## 動作確認

### 1. バックエンドの確認

```bash
# ヘルスチェック
curl http://localhost:8000/health

# 期待するレスポンス
# {"status":"ok","database":"connected"}
```

### 2. フロントエンドの確認

```bash
cd frontend/kotonoha_app
flutter run -d chrome
```

ブラウザでアプリが起動し、ホーム画面が表示されることを確認します。

### 3. データベースの確認

```bash
# PostgreSQLに接続
docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db

# テーブル一覧を確認
\dt

# ai_conversion_historyテーブルの構造を確認
\d ai_conversion_history

# 終了
\q
```

## トラブルシューティング

### Docker関連

#### コンテナが起動しない

```bash
# ログを確認
docker-compose logs

# コンテナを再ビルド
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### ポートが使用中

```bash
# macOS/Linux: ポートを使用しているプロセスを確認
lsof -i :5432
lsof -i :8000

# プロセスを終了
kill -9 <PID>
```

#### ボリュームのリセット

```bash
# すべてのボリュームを削除（データが消えます）
docker-compose down -v
docker-compose up -d
```

### Python関連

#### 仮想環境がアクティブにならない

```bash
# パスを確認
which python

# 明示的にアクティベート
source /path/to/kotonoha/backend/venv/bin/activate
```

#### パッケージのインストールエラー

```bash
# pipをアップグレード
pip install --upgrade pip

# キャッシュをクリア
pip cache purge

# 再インストール
pip install -r requirements.txt --force-reinstall
```

#### マイグレーションエラー

```bash
# マイグレーション状態を確認
alembic current

# 履歴を確認
alembic history

# 特定のリビジョンにダウングレード
alembic downgrade <revision>

# ヘッドにアップグレード
alembic upgrade head
```

### Flutter関連

#### パッケージ取得エラー

```bash
# キャッシュをクリア
flutter clean
flutter pub cache repair

# 再取得
flutter pub get
```

#### コード生成エラー

```bash
# キャッシュを削除して再生成
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Webビルドエラー

```bash
# Webを有効化
flutter config --enable-web

# 再ビルド
flutter clean
flutter pub get
flutter run -d chrome
```

#### iOSビルドエラー（macOS）

```bash
cd ios
pod install --repo-update
cd ..
flutter clean
flutter run
```

### データベース関連

#### 接続エラー

1. `.env` ファイルの設定を確認
2. PostgreSQLコンテナが起動しているか確認
3. ポート5432が正しいか確認

```bash
# 接続テスト
docker exec -it kotonoha_postgres pg_isready -U kotonoha_user -d kotonoha_db
```

#### マイグレーションが適用されない

```bash
# alembic_version テーブルを確認
docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db -c "SELECT * FROM alembic_version"

# 必要に応じてリセット
docker exec -it kotonoha_postgres psql -U kotonoha_user -d kotonoha_db -c "DELETE FROM alembic_version"
alembic upgrade head
```

### 一般的な問題

#### 環境変数が読み込まれない

```bash
# .env ファイルの存在確認
ls -la .env

# 内容確認（機密情報に注意）
cat .env | head -5

# 環境変数の確認
echo $POSTGRES_USER
```

#### Git関連

```bash
# .gitignore が正しく動作しているか確認
git status

# キャッシュをクリアして再追加
git rm -r --cached .
git add .
```

---

## 追加リソース

- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [FastAPI公式ドキュメント](https://fastapi.tiangolo.com/)
- [Docker公式ドキュメント](https://docs.docker.com/)
- [PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/)
- [Alembic公式ドキュメント](https://alembic.sqlalchemy.org/)

## サポート

問題が解決しない場合は、以下の情報を含めてIssueを作成してください:

1. エラーメッセージ（全文）
2. 実行したコマンド
3. 環境情報（OS、各ツールのバージョン）
4. 再現手順
