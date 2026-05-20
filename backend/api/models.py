"""
api/models.py — Global model store, loading, and constants
"""

import json
import os
import pickle
from typing import Any, Dict, List

import numpy as np

# ──────────────────────── Paths ────────────────────────
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODELS_DIR = os.path.join(ROOT, "models")
FEEDBACK_DB = os.path.join(ROOT, "feedback.db")

# ──────────────────────── Constants ────────────────────
MODEL_VERSION = "2.0.0"
CATEGORIES = ["Métal", "Papier", "Plastique", "Verre"]
RECYCLABILITY = {"Papier": 1.0, "Verre": 0.9, "Métal": 0.85, "Plastique": 0.7}

# ──────────────────────── Global model store ───────────
models: Dict[str, Any] = {}


# ──────────────────────── Loaders ──────────────────────
def load_pickle(path: str):
    """Load a pickle file."""
    with open(path, "rb") as f:
        return pickle.load(f)


def try_mlflow_or_pkl(registry_name: str, pkl_path: str):
    """Try loading from MLflow Model Registry, fall back to .pkl."""
    try:
        import mlflow

        tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
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


def load_all_models() -> None:
    """Load all models at startup."""
    print("Loading models...")

    # Classifier
    models["classifier"] = try_mlflow_or_pkl(
        "waste-classifier",
        os.path.join(MODELS_DIR, "classifier_best.pkl"),
    )
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
    reg = models["regressor"]
    if hasattr(reg, "feature_names_in_"):
        models["reg_features"] = list(reg.feature_names_in_)
        print(f"  Regressor features: {len(models['reg_features'])} cols")
    else:
        models["reg_features"] = None

    # KMeans
    models["kmeans"] = load_pickle(os.path.join(MODELS_DIR, "kmeans_best.pkl"))
    print(f"  [OK] Loaded KMeans (k={models['kmeans'].n_clusters})")

    # NLP model + vectorizer
    nlp_dir = os.path.join(MODELS_DIR, "nlp")
    models["nlp_info"] = load_pickle(os.path.join(nlp_dir, "nlp_model_best.pkl"))
    models["nlp_vectorizer"] = load_pickle(os.path.join(nlp_dir, "vectorizer_best.pkl"))
    models["nlp_label_encoder"] = load_pickle(
        os.path.join(nlp_dir, "label_encoder.pkl")
    )
    print(f"  [OK] Loaded NLP model: {models['nlp_info']['name']}")

    # Multimodal
    models["multimodal"] = load_pickle(
        os.path.join(MODELS_DIR, "fusion", "multimodal_best.pkl")
    )
    print(f"  [OK] Loaded multimodal: {models['multimodal']['label']}")

    # Load training scores
    scores_path = os.path.join(MODELS_DIR, "model_scores.json")
    if os.path.exists(scores_path):
        with open(scores_path) as f:
            models["scores"] = json.load(f)
        print(f"  [OK] Loaded training scores from model_scores.json")
    else:
        models["scores"] = {}
        print("  [WARN] model_scores.json not found, scores will be 0")

    print("All models loaded [OK]")
