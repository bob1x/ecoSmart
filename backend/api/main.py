"""
api/main.py — FastAPI application entry point
================================================
Slim orchestrator: creates the app, registers middleware, mounts routers,
and serves the Flutter web build as static files for unified deployment.
"""

import os
import warnings
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from prometheus_fastapi_instrumentator import Instrumentator

from api.models import MODEL_VERSION, ROOT, load_all_models, models
from api.schemas import HealthResponse
from api.services import init_feedback_db
from api.routes.predict import router as predict_router
from api.routes.feedback import router as feedback_router
from api.routes.export import router as export_router
from api.routes.mlops import router as mlops_router

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

# CORS — allow Flutter web app to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics
Instrumentator().instrument(app).expose(app)

# ──────────────────────── API Routes ───────────────────
app.include_router(predict_router)
app.include_router(feedback_router)
app.include_router(export_router)
app.include_router(mlops_router)


@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint."""
    return HealthResponse(status="ok", model_version=MODEL_VERSION)


# ──────────────────────── Static Files (Flutter Web) ───
# Mount AFTER API routes so API endpoints take priority.
# Serves the Flutter web build from backend/static/
if os.path.isdir(STATIC_DIR):
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static_assets")

    @app.get("/{full_path:path}")
    async def serve_spa(request: Request, full_path: str):
        """Serve Flutter SPA — returns index.html for all non-API routes."""
        # Try to serve the exact file (JS, CSS, images, etc.)
        file_path = os.path.join(STATIC_DIR, full_path)
        if os.path.isfile(file_path):
            return FileResponse(file_path)
        # Otherwise return index.html (SPA client-side routing)
        index = os.path.join(STATIC_DIR, "index.html")
        if os.path.isfile(index):
            return FileResponse(index)
        return FileResponse(file_path)  # will 404 naturally
