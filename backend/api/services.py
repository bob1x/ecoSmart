"""
api/services.py — Business logic: scoring, feature engineering, text preprocessing
"""

import re
import sqlite3

import numpy as np
import pandas as pd

from api.models import CATEGORIES, FEEDBACK_DB, RECYCLABILITY, models
from api.schemas import NumericInput


# ──────────────────────── EcoScore ─────────────────────
def compute_eco_score(
    categorie: str, confidence: float, prix_revente: float = 0.0
) -> int:
    """Compute a composite EcoScore (0–100).

    Formula: base = recyclability_weight × confidence × 80
             price_bonus = min(prix / 20, 20)   (capped at 20 pts)
             eco_score = clamp(base + price_bonus, 0, 100)
    """
    weight = RECYCLABILITY.get(categorie, 0.5)
    base = weight * confidence * 80
    price_bonus = min(abs(prix_revente) / 20.0, 20.0)
    return int(max(0, min(100, base + price_bonus)))


# ──────────────────────── Feature Engineering ──────────
def build_features_for_model(
    inp: NumericInput,
    feature_names: list,
    prix_revente: float = 0.0,
) -> pd.DataFrame:
    """Build a feature DataFrame that exactly matches the model's training schema."""
    row = {}
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
        elif feat == "Prix_Revente":
            row[feat] = prix_revente
        elif feat.startswith("Source_"):
            source_val = feat.replace("Source_", "")
            row[feat] = 1.0 if inp.Source == source_val else 0.0
        else:
            row[feat] = 0.0

    return pd.DataFrame([row])[feature_names]


def estimate_prix(inp: NumericInput) -> float:
    """Estimate Prix_Revente with a uniform category prior.

    Averages the price prediction across all categories since
    the true category is not yet known.
    """
    reg = models["regressor"]
    reg_feats = models.get("reg_features")
    if not reg_feats:
        return 0.0

    input_values = {
        "Poids": inp.Poids,
        "Volume": inp.Volume,
        "Conductivite": inp.Conductivite,
        "Opacite": inp.Opacite,
        "Rigidite": inp.Rigidite,
    }

    prices = []
    for cat in CATEGORIES:
        reg_row = {}
        for feat in reg_feats:
            if feat in input_values:
                reg_row[feat] = input_values[feat]
            elif feat.startswith("Categorie_"):
                cat_val = feat.replace("Categorie_", "")
                reg_row[feat] = 1.0 if cat == cat_val else 0.0
            elif feat.startswith("Source_"):
                src_val = feat.replace("Source_", "")
                reg_row[feat] = 1.0 if inp.Source == src_val else 0.0
            else:
                reg_row[feat] = 0.0
        X_reg = pd.DataFrame([reg_row])[reg_feats]
        prices.append(float(reg.predict(X_reg)[0]))

    return float(np.mean(prices))


# ──────────────────────── Text Preprocessing ───────────
_FR_STOPWORDS = {
    "le",
    "la",
    "les",
    "de",
    "du",
    "des",
    "un",
    "une",
    "et",
    "en",
    "à",
    "au",
    "aux",
    "est",
    "son",
    "sa",
    "ses",
    "que",
    "qui",
    "dans",
    "sur",
    "par",
    "pour",
    "avec",
    "ce",
    "il",
    "elle",
    "nous",
    "vous",
    "ils",
    "se",
    "ne",
    "pas",
    "plus",
    "très",
    "tout",
    "ou",
    "mais",
    "donc",
    "car",
    "ni",
    "si",
    "comme",
    "ont",
    "été",
    "être",
    "avoir",
    "fait",
    "peut",
    "cette",
    "ces",
    "mon",
    "ton",
    "leur",
    "notre",
    "votre",
    "quel",
    "quoi",
    "dont",
    "y",
    "là",
    "ici",
    "entre",
    "avant",
    "après",
    "sans",
    "sous",
    "vers",
    "chez",
    "depuis",
    "encore",
    "aussi",
    "bien",
    "mal",
    "peu",
    "trop",
    "assez",
    "dechet",
    "collecte",
    "rapport",
    "materiau",
    "echantillon",
    "lot",
    "site",
    "non",
    "renseigne",
    "poids",
    "volume",
}


def preprocess_text(text: str) -> str:
    """Lightweight text preprocessing — no spacy dependency."""
    if not isinstance(text, str) or not text.strip():
        return ""

    text = text.lower()
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\d+", " ", text)
    text = re.sub(r"\s+", " ", text).strip()

    tokens = [w for w in text.split() if len(w) > 1 and w not in _FR_STOPWORDS]
    return " ".join(tokens)


# ──────────────────────── Feedback DB ──────────────────
def init_feedback_db() -> None:
    """Create the feedback table if it doesn't exist."""
    conn = sqlite3.connect(FEEDBACK_DB)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS feedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            predicted_label TEXT NOT NULL,
            correct_label TEXT NOT NULL,
            is_correct INTEGER NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()
