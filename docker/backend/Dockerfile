FROM python:3.10-slim

WORKDIR /app

# システム依存関係インストール
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Python依存関係インストール
# 開発用コンテナなので、コンテナ内で pytest / ruff / black を実行できるよう
# requirements-dev.txt（先頭で requirements.txt を -r で取り込む）を入れる。
# 本番イメージ（backend/Dockerfile）は requirements.txt のみを入れる。
COPY backend/requirements.txt backend/requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt

# アプリケーションコピー
COPY backend/ .

# 実行
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
