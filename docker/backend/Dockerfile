FROM python:3.12-slim
WORKDIR /app
COPY backend/requirements-dev.txt backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY backend/ .
# --no-proxy-headers: XFF の解釈は app/ratelimit.py の1箇所に閉じる（I-2）
CMD ["uvicorn", "app.main:create_app", "--factory", "--no-proxy-headers", "--host", "0.0.0.0", "--port", "8000", "--reload"]
