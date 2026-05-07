"""
api/main.py — FastAPI application for Eco-Smart Classifier
============================================================
Endpoints:
  POST /predict/numeric    → categorie + prix_revente + confidence
  POST /predict/text       → categorie + confidence
  POST /predict/multimodal → categorie + prix_revente + confidence + cluster_id
  GET  /health             → status + model_version
  GET  /metrics            → Prometheus metrics
"""

import os
import sys
import pickle
import warnings
from contextlib import asynccontextmanager
from typing import Any, Dict

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator

from api.schemas import (
    HealthResponse,
    MultimodalInput,
    MultimodalOutput,
    NumericInput,
    NumericOutput,
    TextInput,
    TextOutput,
)

warnings.filterwarnings("ignore")

# ──────────────────────── Paths ────────────────────────
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODELS_DIR = os.path.join(ROOT, "models")

# ──────────────────────── Global model store ───────────
models: Dict[str, Any] = {}

MODEL_VERSION = "1.0.0"


# ──────────────────────── Helpers ──────────────────────
def load_pickle(path: str):
    """Load a pickle file."""
    with open(path, "rb") as f:
        return pickle.load(f)


def try_mlflow_or_pkl(registry_name: str, pkl_path: str):
    """Try loading from MLflow Model Registry, fall back to .pkl."""
    try:
        import mlflow

        tracking_db = (
            "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
        )
        mlflow.set_tracking_uri(tracking_db)
        model_uri = f"models:/{registry_name}/latest"
        model = mlflow.sklearn.load_model(model_uri)
        print(f"  [OK] Loaded '{registry_name}' from MLflow Registry")
        return model
    except Exception:
        if os.path.exists(pkl_path):
            model = load_pickle(pkl_path)
            print(f"  [OK] Loaded from pkl: {pkl_path}")
            return model
        raise FileNotFoundError(
            f"No model found in registry '{registry_name}' or at '{pkl_path}'"
        )


def load_all_models():
    """Load all models at startup."""
    print("Loading models...")

    # Classifier
    models["classifier"] = try_mlflow_or_pkl(
        "waste-classifier",
        os.path.join(MODELS_DIR, "classifier_best.pkl"),
    )

    # Read feature names from the classifier for dynamic feature building
    clf = models["classifier"]
    if hasattr(clf, "feature_names_in_"):
        models["clf_features"] = list(clf.feature_names_in_)
        print(f"  Classifier features: {len(models['clf_features'])} cols")
    else:
        models["clf_features"] = None

    # Regressor
    models["regressor"] = try_mlflow_or_pkl(
        "waste-regressor",
        os.path.join(MODELS_DIR, "regressor_best.pkl"),
    )

    # Read regressor feature names
    reg = models["regressor"]
    if hasattr(reg, "feature_names_in_"):
        models["reg_features"] = list(reg.feature_names_in_)
        print(f"  Regressor features: {len(models['reg_features'])} cols")
    else:
        models["reg_features"] = None

    # KMeans
    models["kmeans"] = load_pickle(
        os.path.join(MODELS_DIR, "kmeans_best.pkl")
    )
    print(f"  [OK] Loaded KMeans (k={models['kmeans'].n_clusters})")

    # NLP model + vectorizer
    nlp_dir = os.path.join(MODELS_DIR, "nlp")
    models["nlp_info"] = load_pickle(
        os.path.join(nlp_dir, "nlp_model_best.pkl")
    )
    models["nlp_vectorizer"] = load_pickle(
        os.path.join(nlp_dir, "vectorizer_best.pkl")
    )
    models["nlp_label_encoder"] = load_pickle(
        os.path.join(nlp_dir, "label_encoder.pkl")
    )
    print(f"  [OK] Loaded NLP model: {models['nlp_info']['name']}")

    # Multimodal
    models["multimodal"] = load_pickle(
        os.path.join(MODELS_DIR, "fusion", "multimodal_best.pkl")
    )
    print(f"  [OK] Loaded multimodal: {models['multimodal']['label']}")

    print("All models loaded [OK]")


# ──────────────────────── Preprocessing ────────────────
# Classification label classes (same order as training)
CATEGORIES = ["Métal", "Papier", "Plastique", "Verre"]


def build_features_for_model(inp: NumericInput, feature_names: list) -> pd.DataFrame:
    """Build a feature DataFrame that exactly matches the model's training schema.

    Dynamically reads feature_names_in_ from the model and fills in:
    - numeric values from the input
    - one-hot encoded Source columns
    - any other columns default to 0
    """
    row = {}
    # Map input fields to column names
    input_values = {
        "Poids": inp.Poids,
        "Volume": inp.Volume,
        "Conductivite": inp.Conductivite,
        "Opacite": inp.Opacite,
        "Rigidite": inp.Rigidite,
    }

    for feat in feature_names:
        if feat in input_values:
            row[feat] = input_values[feat]
        elif feat.startswith("Source_"):
            source_val = feat.replace("Source_", "")
            row[feat] = 1.0 if inp.Source == source_val else 0.0
        else:
            # Columns like Prix_Revente — set to 0 (the model was trained with it
            # but for classification we don't have it at prediction time)
            row[feat] = 0.0

    return pd.DataFrame([row])[feature_names]  # enforce column order


def preprocess_text(text: str):
    """Preprocess text for NLP prediction."""
    # Lazy import to avoid loading spaCy at module level
    sys.path.insert(0, ROOT)
    from src.nlp.preprocess import preprocess as preprocess_fn

    tokens = preprocess_fn(text)
    return " ".join(tokens)


# ──────────────────────── Lifespan ─────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load models at startup, cleanup at shutdown."""
    load_all_models()
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
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics
Instrumentator().instrument(app).expose(app)


# ──────────────────────── Endpoints ────────────────────


@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint."""
    return HealthResponse(status="ok", model_version=MODEL_VERSION)


@app.post("/predict/numeric", response_model=NumericOutput)
async def predict_numeric(inp: NumericInput):
    """Predict category and resale price from numeric features."""
    try:
        # Classification
        clf = models["classifier"]
        clf_feats = models.get("clf_features")
        if clf_feats:
            X = build_features_for_model(inp, clf_feats)
        else:
            # Fallback: build minimal features
            X = pd.DataFrame([{
                "Poids": inp.Poids, "Volume": inp.Volume,
                "Conductivite": inp.Conductivite, "Opacite": inp.Opacite,
                "Rigidite": inp.Rigidite,
            }])

        if hasattr(clf, "predict_proba"):
            proba = clf.predict_proba(X)[0]
            pred_idx = int(np.argmax(proba))
            confidence = float(proba[pred_idx])
        else:
            pred_idx = int(clf.predict(X)[0])
            confidence = 0.0

        categorie = CATEGORIES[pred_idx] if pred_idx < len(CATEGORIES) else str(pred_idx)

        # Regression
        reg = models["regressor"]
        reg_feats = models.get("reg_features")
        if reg_feats:
            # Build regression features dynamically
            reg_row = {}
            input_values = {
                "Poids": inp.Poids, "Volume": inp.Volume,
                "Conductivite": inp.Conductivite, "Opacite": inp.Opacite,
                "Rigidite": inp.Rigidite,
            }
            for feat in reg_feats:
                if feat in input_values:
                    reg_row[feat] = input_values[feat]
                elif feat.startswith("Categorie_"):
                    cat_val = feat.replace("Categorie_", "")
                    reg_row[feat] = 1.0 if categorie == cat_val else 0.0
                elif feat.startswith("Source_"):
                    src_val = feat.replace("Source_", "")
                    reg_row[feat] = 1.0 if inp.Source == src_val else 0.0
                else:
                    reg_row[feat] = 0.0
            X_reg = pd.DataFrame([reg_row])[reg_feats]
        else:
            X_reg = pd.DataFrame([{
                "Poids": inp.Poids, "Volume": inp.Volume,
                "Conductivite": inp.Conductivite, "Opacite": inp.Opacite,
                "Rigidite": inp.Rigidite,
            }])

        prix = float(reg.predict(X_reg)[0])

        return NumericOutput(
            categorie=categorie,
            prix_revente=round(prix, 2),
            confidence=round(confidence, 4),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/text", response_model=TextOutput)
async def predict_text(inp: TextInput):
    """Predict category from text report."""
    try:
        processed = preprocess_text(inp.rapport)

        vec_info = models["nlp_vectorizer"]
        nlp_clf = models["nlp_info"]["classifier"]
        le = models["nlp_label_encoder"]

        vec = vec_info["vec"]
        vec_type = vec_info["type"]

        if vec_type == "sklearn":
            X = vec.transform([processed])
        else:
            # gensim Word2Vec / FastText — mean pool
            tokens = processed.split()
            dim = vec.wv.vector_size
            vecs = [vec.wv[t] for t in tokens if t in vec.wv]
            if vecs:
                X = np.array([np.mean(vecs, axis=0)])
            else:
                X = np.zeros((1, dim))

        if hasattr(nlp_clf, "predict_proba"):
            proba = nlp_clf.predict_proba(X)[0]
            pred_idx = int(np.argmax(proba))
            confidence = float(proba[pred_idx])
        else:
            pred_idx = int(nlp_clf.predict(X)[0])
            confidence = 0.0

        categorie = le.inverse_transform([pred_idx])[0]

        return TextOutput(
            categorie=categorie,
            confidence=round(confidence, 4),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/multimodal", response_model=MultimodalOutput)
async def predict_multimodal(inp: MultimodalInput):
    """Predict category, price, confidence and cluster from all features."""
    try:
        # Reuse numeric prediction logic
        numeric_inp = NumericInput(
            Poids=inp.Poids,
            Volume=inp.Volume,
            Conductivite=inp.Conductivite,
            Opacite=inp.Opacite,
            Rigidite=inp.Rigidite,
            Source=inp.Source,
        )

        # Classification
        clf = models["classifier"]
        clf_feats = models.get("clf_features")
        if clf_feats:
            X = build_features_for_model(numeric_inp, clf_feats)
        else:
            X = pd.DataFrame([{
                "Poids": inp.Poids, "Volume": inp.Volume,
                "Conductivite": inp.Conductivite, "Opacite": inp.Opacite,
                "Rigidite": inp.Rigidite,
            }])

        if hasattr(clf, "predict_proba"):
            proba = clf.predict_proba(X)[0]
            pred_idx = int(np.argmax(proba))
            confidence = float(proba[pred_idx])
        else:
            pred_idx = int(clf.predict(X)[0])
            confidence = 0.0

        categorie = CATEGORIES[pred_idx] if pred_idx < len(CATEGORIES) else str(pred_idx)

        # Regression
        reg = models["regressor"]
        reg_feats = models.get("reg_features")
        if reg_feats:
            reg_row = {}
            input_values = {
                "Poids": inp.Poids, "Volume": inp.Volume,
                "Conductivite": inp.Conductivite, "Opacite": inp.Opacite,
                "Rigidite": inp.Rigidite,
            }
            for feat in reg_feats:
                if feat in input_values:
                    reg_row[feat] = input_values[feat]
                elif feat.startswith("Categorie_"):
                    cat_val = feat.replace("Categorie_", "")
                    reg_row[feat] = 1.0 if categorie == cat_val else 0.0
                elif feat.startswith("Source_"):
                    src_val = feat.replace("Source_", "")
                    reg_row[feat] = 1.0 if inp.Source == src_val else 0.0
                else:
                    reg_row[feat] = 0.0
            X_reg = pd.DataFrame([reg_row])[reg_feats]
        else:
            X_reg = pd.DataFrame([{
                "Poids": inp.Poids, "Volume": inp.Volume,
                "Conductivite": inp.Conductivite, "Opacite": inp.Opacite,
                "Rigidite": inp.Rigidite,
            }])

        prix = float(reg.predict(X_reg)[0])

        # Clustering
        km = models["kmeans"]
        cluster_features = np.array(
            [[inp.Poids, inp.Volume, inp.Conductivite,
              inp.Opacite, inp.Rigidite, prix]]
        )
        cluster_id = int(km.predict(cluster_features)[0])

        return MultimodalOutput(
            categorie=categorie,
            prix_revente=round(prix, 2),
            confidence=round(confidence, 4),
            cluster_id=cluster_id,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
