"""
api/routes/predict.py — Prediction endpoints (numeric, text, multimodal, explain)
"""

import numpy as np
import pandas as pd
from fastapi import APIRouter, HTTPException

from api.models import CATEGORIES, models
from api.schemas import (MultimodalInput, MultimodalOutput, NumericInput,
                         NumericOutput, TextInput, TextOutput)
from api.services import (build_features_for_model, compute_eco_score,
                          estimate_prix, preprocess_text)

router = APIRouter(tags=["predict"])


@router.post("/predict/numeric", response_model=NumericOutput)
async def predict_numeric(inp: NumericInput):
    """Predict category and resale price from numeric features.

    Uses a 2-pass approach:
    1. Estimate Prix_Revente with uniform category prior
    2. Use estimated price as a feature for classification
    """
    try:
        clf = models["classifier"]
        clf_feats = models.get("clf_features")

        estimated_prix = estimate_prix(inp)

        if clf_feats:
            X = build_features_for_model(inp, clf_feats, prix_revente=estimated_prix)
        else:
            X = pd.DataFrame(
                [
                    {
                        "Poids": inp.Poids,
                        "Volume": inp.Volume,
                        "Conductivite": inp.Conductivite,
                        "Opacite": inp.Opacite,
                        "Rigidite": inp.Rigidite,
                    }
                ]
            )

        if hasattr(clf, "predict_proba"):
            proba = clf.predict_proba(X)[0]
            pred_idx = int(np.argmax(proba))
            confidence = float(proba[pred_idx])
        else:
            pred_idx = int(clf.predict(X)[0])
            confidence = 0.0

        categorie = (
            CATEGORIES[pred_idx] if pred_idx < len(CATEGORIES) else str(pred_idx)
        )

        # Final regression with the predicted category
        reg = models["regressor"]
        reg_feats = models.get("reg_features")
        if reg_feats:
            reg_row = {}
            input_values = {
                "Poids": inp.Poids,
                "Volume": inp.Volume,
                "Conductivite": inp.Conductivite,
                "Opacite": inp.Opacite,
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
            X_reg = pd.DataFrame(
                [
                    {
                        "Poids": inp.Poids,
                        "Volume": inp.Volume,
                        "Conductivite": inp.Conductivite,
                        "Opacite": inp.Opacite,
                        "Rigidite": inp.Rigidite,
                    }
                ]
            )

        prix = float(reg.predict(X_reg)[0])
        conf = round(confidence, 4)
        price = round(prix, 2)

        return NumericOutput(
            categorie=categorie,
            prix_revente=price,
            confidence=conf,
            eco_score=compute_eco_score(categorie, conf, price),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict/text", response_model=TextOutput)
async def predict_text(inp: TextInput):
    """Predict category from text report, returning top keywords."""
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
            tokens = processed.split()
            dim = vec.wv.vector_size
            vecs = [vec.wv[t] for t in tokens if t in vec.wv]
            X = np.array([np.mean(vecs, axis=0)]) if vecs else np.zeros((1, dim))

        if hasattr(nlp_clf, "predict_proba"):
            proba = nlp_clf.predict_proba(X)[0]
            pred_idx = int(np.argmax(proba))
            confidence = float(proba[pred_idx])
        else:
            pred_idx = int(nlp_clf.predict(X)[0])
            confidence = 0.0

        categorie = le.inverse_transform([pred_idx])[0]

        # Extract top keywords
        top_kw: list[str] = []
        if vec_type == "sklearn" and hasattr(nlp_clf, "coef_"):
            try:
                feature_names = vec.get_feature_names_out()
                class_weights = nlp_clf.coef_[pred_idx]
                nonzero = X.toarray()[0]
                weighted = class_weights * nonzero
                top_indices = np.argsort(weighted)[::-1][:5]
                top_kw = [feature_names[i] for i in top_indices if weighted[i] > 0]
            except Exception:
                top_kw = processed.split()[:5]
        else:
            top_kw = processed.split()[:5]

        conf = round(confidence, 4)
        return TextOutput(
            categorie=categorie,
            confidence=conf,
            eco_score=compute_eco_score(categorie, conf),
            top_keywords=top_kw,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict/multimodal", response_model=MultimodalOutput)
async def predict_multimodal(inp: MultimodalInput):
    """Predict category, price, confidence and cluster from all features."""
    try:
        numeric_inp = NumericInput(
            Poids=inp.Poids,
            Volume=inp.Volume,
            Conductivite=inp.Conductivite,
            Opacite=inp.Opacite,
            Rigidite=inp.Rigidite,
            Source=inp.Source,
        )

        estimated_prix = estimate_prix(numeric_inp)

        clf = models["classifier"]
        clf_feats = models.get("clf_features")
        if clf_feats:
            X = build_features_for_model(
                numeric_inp, clf_feats, prix_revente=estimated_prix
            )
        else:
            X = pd.DataFrame(
                [
                    {
                        "Poids": inp.Poids,
                        "Volume": inp.Volume,
                        "Conductivite": inp.Conductivite,
                        "Opacite": inp.Opacite,
                        "Rigidite": inp.Rigidite,
                    }
                ]
            )

        if hasattr(clf, "predict_proba"):
            proba = clf.predict_proba(X)[0]
            pred_idx = int(np.argmax(proba))
            confidence = float(proba[pred_idx])
        else:
            pred_idx = int(clf.predict(X)[0])
            confidence = 0.0

        categorie = (
            CATEGORIES[pred_idx] if pred_idx < len(CATEGORIES) else str(pred_idx)
        )

        # Regression
        reg = models["regressor"]
        reg_feats = models.get("reg_features")
        if reg_feats:
            reg_row = {}
            input_values = {
                "Poids": inp.Poids,
                "Volume": inp.Volume,
                "Conductivite": inp.Conductivite,
                "Opacite": inp.Opacite,
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
            X_reg = pd.DataFrame(
                [
                    {
                        "Poids": inp.Poids,
                        "Volume": inp.Volume,
                        "Conductivite": inp.Conductivite,
                        "Opacite": inp.Opacite,
                        "Rigidite": inp.Rigidite,
                    }
                ]
            )

        prix = float(reg.predict(X_reg)[0])

        # Clustering
        km = models["kmeans"]
        cluster_features = np.array(
            [[inp.Poids, inp.Volume, inp.Conductivite, inp.Opacite, inp.Rigidite, prix]]
        )
        cluster_id = int(km.predict(cluster_features)[0])

        conf = round(confidence, 4)
        price = round(prix, 2)
        return MultimodalOutput(
            categorie=categorie,
            prix_revente=price,
            confidence=conf,
            cluster_id=cluster_id,
            eco_score=compute_eco_score(categorie, conf, price),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict/explain")
async def predict_explain(inp: NumericInput):
    """Return feature importance breakdown (lightweight SHAP proxy)."""
    try:
        clf = models["classifier"]
        clf_feats = models.get("clf_features")

        estimated_prix = estimate_prix(inp)

        if clf_feats:
            X = build_features_for_model(inp, clf_feats, prix_revente=estimated_prix)
        else:
            X = pd.DataFrame(
                [
                    {
                        "Poids": inp.Poids,
                        "Volume": inp.Volume,
                        "Conductivite": inp.Conductivite,
                        "Opacite": inp.Opacite,
                        "Rigidite": inp.Rigidite,
                    }
                ]
            )

        if hasattr(clf, "predict_proba"):
            proba = clf.predict_proba(X)[0]
            pred_idx = int(np.argmax(proba))
            confidence = float(proba[pred_idx])
        else:
            pred_idx = int(clf.predict(X)[0])
            confidence = 0.0

        categorie = (
            CATEGORIES[pred_idx] if pred_idx < len(CATEGORIES) else str(pred_idx)
        )

        contributions = []
        if hasattr(clf, "feature_importances_") and clf_feats:
            importances = clf.feature_importances_
            x_values = X.values[0]
            x_abs = np.abs(x_values)
            x_norm = x_abs / (x_abs.sum() + 1e-9)
            weighted = importances * x_norm
            weighted_norm = weighted / (weighted.sum() + 1e-9)

            indices = np.argsort(weighted_norm)[::-1]
            for idx in indices[:8]:
                name = clf_feats[idx]
                display = name.replace("Categorie_", "Cat: ").replace(
                    "Source_", "Src: "
                )
                contributions.append(
                    {
                        "feature": display,
                        "importance": round(float(importances[idx]), 4),
                        "contribution": round(float(weighted_norm[idx]) * 100, 1),
                        "value": round(float(x_values[idx]), 4),
                        "direction": "positive",
                    }
                )
        else:
            raw_feats = ["Poids", "Volume", "Conductivite", "Opacite", "Rigidite"]
            raw_vals = [
                inp.Poids,
                inp.Volume,
                inp.Conductivite,
                inp.Opacite,
                inp.Rigidite,
            ]
            total = sum(abs(v) for v in raw_vals) + 1e-9
            for f, v in zip(raw_feats, raw_vals):
                contributions.append(
                    {
                        "feature": f,
                        "importance": round(abs(v) / total, 4),
                        "contribution": round(abs(v) / total * 100, 1),
                        "value": round(v, 4),
                        "direction": "positive",
                    }
                )

        return {
            "categorie": categorie,
            "confidence": round(confidence, 4),
            "contributions": contributions,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
