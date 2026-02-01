# 開発コマンド一覧

## Docker環境
```bash
docker-compose up -d              # 全サービス起動（PostgreSQL + Backend）
docker-compose down               # 停止
docker-compose logs -f backend    # バックエンドログ確認
```

## バックエンド（backend/ディレクトリ）
```bash
# サーバー起動
cd backend && uvicorn app.main:app --reload

# テスト
cd backend && pytest
cd backend && pytest --cov=app --cov-report=html --cov-report=term-missing

# リンター・フォーマッター
cd backend && ruff check app tests
cd backend && ruff check app tests --fix
cd backend && black app tests

# Makefileショートカット
cd backend && make test        # テスト実行
cd backend && make lint        # リンター
cd backend && make format      # フォーマット
cd backend && make test-cov    # カバレッジ付きテスト

# DBマイグレーション
cd backend && alembic upgrade head
cd backend && alembic revision --autogenerate -m "description"
```

## フロントエンド（frontend/kotonoha_app/ディレクトリ）
```bash
# アプリ起動
cd frontend/kotonoha_app && flutter run -d chrome

# テスト
cd frontend/kotonoha_app && flutter test

# コード生成（Riverpod, JSON serialization等）
cd frontend/kotonoha_app && flutter pub run build_runner build --delete-conflicting-outputs

# 解析・フォーマット
cd frontend/kotonoha_app && flutter analyze
cd frontend/kotonoha_app && dart format .

# 依存関係
cd frontend/kotonoha_app && flutter pub get
```

## Pre-commit hooks
```bash
pre-commit run --all-files    # 全ファイルチェック
```

## Git（Darwin/macOS）
```bash
git status
git diff
git log --oneline -20
git add <file>
git commit -m "message (TASK-XXXX)"
```

## システムユーティリティ（macOS/Darwin）
```bash
ls -la
find . -name "*.dart" -type f
grep -r "pattern" --include="*.dart" .
```
