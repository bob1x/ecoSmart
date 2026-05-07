"""
tests/test_api.py — FastAPI endpoint tests
============================================
Uses TestClient (no server needed).
- GET /health returns 200 and {"status": "ok"}
- POST /predict/numeric with valid payload → 200 + correct schema
- POST /predict/text with valid payload → 200 + correct schema
- POST /predict/numeric with missing field → 422
"""

import os
import sys

import pytest


def spacy_available():
    """Check if spaCy is installed (needed for text endpoint)."""
    try:
        import spacy
        return True
    except ImportError:
        return False

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Check if models exist before importing app
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODELS_DIR = os.path.join(ROOT, "models")

REQUIRED_MODELS = [
    os.path.join(MODELS_DIR, "classifier_best.pkl"),
    os.path.join(MODELS_DIR, "regressor_best.pkl"),
    os.path.join(MODELS_DIR, "kmeans_best.pkl"),
    os.path.join(MODELS_DIR, "nlp", "nlp_model_best.pkl"),
    os.path.join(MODELS_DIR, "nlp", "vectorizer_best.pkl"),
    os.path.join(MODELS_DIR, "nlp", "label_encoder.pkl"),
    os.path.join(MODELS_DIR, "fusion", "multimodal_best.pkl"),
]


def models_available():
    """Check if all required model files exist."""
    return all(os.path.exists(p) for p in REQUIRED_MODELS)


# Conditional import — skip all tests if models are missing
pytestmark = pytest.mark.skipif(
    not models_available(),
    reason="Model files not found — run training pipeline first",
)


@pytest.fixture(scope="module")
def client():
    """Create TestClient for the FastAPI app."""
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as c:
        yield c


# ──────────── Valid payloads ────────────
VALID_NUMERIC = {
    "Poids": 47.28,
    "Volume": 64.70,
    "Conductivite": 0.0,
    "Opacite": 1.0,
    "Rigidite": 3.0,
    "Source": "Usine_A",
}

VALID_TEXT = {
    "rapport": (
        "Lot de papier récupéré dans un site non renseigné. "
        "Poids léger de 16.7 kg, volume moyen. "
        "Matériau souple, non conducteur, aspect très opaque."
    )
}

VALID_MULTIMODAL = {
    **VALID_NUMERIC,
    "rapport": (
        "Lot plastique à l'Usine A. Volume 64.7 L, poids 47.3 kg. "
        "Aspect indéterminée, rigidité moyenne."
    ),
}


# ──────────── Health ────────────
class TestHealth:
    def test_health_returns_200(self, client):
        """GET /health returns 200."""
        resp = client.get("/health")
        assert resp.status_code == 200

    def test_health_status_ok(self, client):
        """GET /health returns status=ok."""
        resp = client.get("/health")
        data = resp.json()
        assert data["status"] == "ok"
        assert "model_version" in data


# ──────────── Numeric prediction ────────────
class TestNumericPredict:
    def test_valid_payload_returns_200(self, client):
        """POST /predict/numeric with valid payload → 200."""
        resp = client.post("/predict/numeric", json=VALID_NUMERIC)
        assert resp.status_code == 200

    def test_valid_payload_schema(self, client):
        """Response contains categorie, prix_revente, confidence."""
        resp = client.post("/predict/numeric", json=VALID_NUMERIC)
        data = resp.json()
        assert "categorie" in data
        assert "prix_revente" in data
        assert "confidence" in data
        assert isinstance(data["categorie"], str)
        assert isinstance(data["prix_revente"], (int, float))
        assert isinstance(data["confidence"], (int, float))

    def test_missing_field_returns_422(self, client):
        """POST /predict/numeric with missing field → 422."""
        incomplete = {"Poids": 47.28, "Volume": 64.70}
        resp = client.post("/predict/numeric", json=incomplete)
        assert resp.status_code == 422


# ──────────── Text prediction ────────────
@pytest.mark.skipif(
    not spacy_available(),
    reason="spaCy not installed — text endpoint requires it",
)
class TestTextPredict:
    def test_valid_payload_returns_200(self, client):
        """POST /predict/text with valid payload → 200."""
        resp = client.post("/predict/text", json=VALID_TEXT)
        assert resp.status_code == 200

    def test_valid_payload_schema(self, client):
        """Response contains categorie and confidence."""
        resp = client.post("/predict/text", json=VALID_TEXT)
        data = resp.json()
        assert "categorie" in data
        assert "confidence" in data
        assert isinstance(data["categorie"], str)

    def test_empty_text_returns_422(self, client):
        """POST /predict/text with too-short text → 422."""
        resp = client.post("/predict/text", json={"rapport": "ab"})
        assert resp.status_code == 422


# ──────────── Multimodal prediction ────────────
class TestMultimodalPredict:
    def test_valid_payload_returns_200(self, client):
        """POST /predict/multimodal with valid payload → 200."""
        resp = client.post("/predict/multimodal", json=VALID_MULTIMODAL)
        assert resp.status_code == 200

    def test_valid_payload_schema(self, client):
        """Response contains categorie, prix_revente, confidence, cluster_id."""
        resp = client.post("/predict/multimodal", json=VALID_MULTIMODAL)
        data = resp.json()
        assert "categorie" in data
        assert "prix_revente" in data
        assert "confidence" in data
        assert "cluster_id" in data
        assert isinstance(data["cluster_id"], int)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
