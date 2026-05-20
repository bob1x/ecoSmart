"""
api/main.py — FastAPI application entry point
================================================
Slim orchestrator: creates the app, registers middleware, mounts routers,
tracks real API metrics, and serves the Flutter web build.
"""

import os
import time
import warnings
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator

from api.metrics_tracker import record_request
from api.models import MODEL_VERSION, ROOT, load_all_models, models
from api.routes.export import router as export_router
from api.routes.feedback import router as feedback_router
from api.routes.mlops import router as mlops_router
from api.routes.predict import router as predict_router
from api.routes.prometheus import router as prometheus_router
from api.schemas import HealthResponse
from api.services import init_feedback_db

warnings.filterwarnings("ignore")

# Path to Flutter web build
STATIC_DIR = os.path.join(ROOT, "static")


# ──────────────────────── Lifespan ─────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load models at startup, init feedback DB, cleanup at shutdown."""
    load_all_models()
    init_feedback_db()
    yield
    models.clear()
    print("Models unloaded")


# ──────────────────────── App ──────────────────────────
app = FastAPI(
    title="Eco-Smart Classifier API",
    description="Waste classification, price prediction, and NLP analysis",
    version=MODEL_VERSION,
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics
Instrumentator().instrument(app).expose(app)


# ──────────────────────── Metrics Middleware ────────────
@app.middleware("http")
async def track_metrics(request: Request, call_next):
    """Record latency and error rate for every API request."""
    # Skip static file requests
    path = request.url.path
    if path.startswith("/static") or "." in path.split("/")[-1]:
        return await call_next(request)

    start = time.perf_counter()
    response = await call_next(request)
    latency_ms = (time.perf_counter() - start) * 1000

    record_request(
        path=path,
        latency_ms=latency_ms,
        is_error=response.status_code >= 400,
    )
    return response


# ──────────────────────── API Routes ───────────────────
app.include_router(predict_router)
app.include_router(feedback_router)
app.include_router(export_router)
app.include_router(mlops_router)
app.include_router(prometheus_router)


@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint."""
    return HealthResponse(status="ok", model_version=MODEL_VERSION)


# ──────────────────────── Static Files (Flutter Web) ───
if os.path.isdir(STATIC_DIR):
    app.mount(
        "/assets",
        StaticFiles(directory=os.path.join(STATIC_DIR, "assets")),
        name="flutter_assets",
    )

    @app.get("/{full_path:path}")
    async def serve_spa(request: Request, full_path: str):
        """Serve Flutter SPA — returns index.html for all non-API routes."""
        file_path = os.path.join(STATIC_DIR, full_path)
        if os.path.isfile(file_path):
            return FileResponse(file_path)
        index = os.path.join(STATIC_DIR, "index.html")
        if os.path.isfile(index):
            return FileResponse(index)
        return FileResponse(file_path)
