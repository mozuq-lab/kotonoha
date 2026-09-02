FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
RUN groupadd -r kotonoha && useradd -r -g kotonoha kotonoha
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/* && rm -rf /wheels
COPY app ./app
RUN chown -R kotonoha:kotonoha /app
USER kotonoha
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/v1/health')" || exit 1
# worker は 1 つ（ADR-002）。--workers を足すと起動ガードで落ちる
# --no-proxy-headers: XFF の解釈は app/ratelimit.py の1箇所に閉じる（I-2）
CMD ["uvicorn", "app.main:create_app", "--factory", "--no-proxy-headers", "--host", "0.0.0.0", "--port", "8000"]
