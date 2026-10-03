from fastapi import FastAPI

app = FastAPI(title="Homelab FastAPI")

@app.get("/")
def root():
    return {
        "message": "Hello from FastAPI on MicroK8s",
        "status": "running"
    }

@app.get("/health")
def health():
    return {"status": "healthy"}
