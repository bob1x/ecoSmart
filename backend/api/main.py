"""
api/main.py — FastAPI application entry point
================================================
Slim orchestrator: creates the app, registers middleware, and mounts routers.
All business logic lives in api/services.py, model loading in api/models.py,
and endpoints in api/routes/*.
"""

import warnings
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator

from api.models import MODEL_VERSION, load_all_models, models
from api.schemas import HealthResponse
from api.services import init_feedback_db
from api.routes.predict import router as predict_router
from api.routes.feedback import router as feedback_router
from api.routes.export import router as export_router
from api.routes.mlops import router as mlops_router

warnings.filterwarnings("ignore")


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

# ──────────────────────── Routes ───────────────────────
app.include_router(predict_router)
app.include_router(feedback_router)
app.include_router(export_router)
app.include_router(mlops_router)


@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint."""
    return HealthResponse(status="ok", model_version=MODEL_VERSION)
