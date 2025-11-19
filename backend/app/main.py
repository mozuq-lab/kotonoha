from fastapi import FastAPI

app = FastAPI(title="kotonoha API", version="1.0.0")


@app.get("/")
async def root() -> dict[str, str]:
    return {"message": "kotonoha API is running"}


@app.get("/health")
async def health_check() -> dict[str, str]:
    return {"status": "ok"}
