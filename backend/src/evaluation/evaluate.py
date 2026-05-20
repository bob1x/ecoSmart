"""
DVC Stage: evaluate
====================
Loads all best models, evaluates on test set,
produces a consolidated evaluation report.
Outputs: reports/evaluation.json
Logs metrics to MLflow.
"""

import json
import os
import pickle
import sys
import warnings

import mlflow
import numpy as np
import pandas as pd
import yaml
from sklearn.impute import SimpleImputer
from sklearn.metrics import (accuracy_score, classification_report, f1_score,
                             mean_absolute_error, mean_squared_error, r2_score)
from sklearn.preprocessing import LabelEncoder, StandardScaler

warnings.filterwarnings("ignore")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODELS_DIR = os.path.join(ROOT, "models")
REPORTS_DIR = os.path.join(ROOT, "reports")
os.makedirs(REPORTS_DIR, exist_ok=True)

RAW_CSV = os.path.join(ROOT, "dataset_ProjetML_2026.csv")


def load_params():
    with open(os.path.join(ROOT, "params.yaml"), "r") as f:
        return yaml.safe_load(f)


def load_pickle(path):
    with open(path, "rb") as f:
        return pickle.load(f)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("DVC Stage: evaluate — Consolidated Evaluation")
    print("=" * 60)

    params = load_params()
    eval_params = params["evaluate"]
    min_accuracy = eval_params["min_accuracy"]
    min_f1 = eval_params["min_f1"]

    # ---- Load raw data for evaluation ----
    df = pd.read_csv(RAW_CSV)

    # ---- 1. Classification evaluation ----
    print("\n--- Classification (Categorie) ---")
    clf_path = os.path.join(MODELS_DIR, "classifier_best.pkl")
    classifier = load_pickle(clf_path)
    print(f"  Loaded classifier from {clf_path}")

    # Prepare data (same pipeline as classification.py)
    df_clf = df.copy()
    df_clf.drop(columns=["Rapport_Collecte"], inplace=True, errors="ignore")
    df_clf.dropna(subset=["Categorie"], inplace=True)

    y_raw = df_clf["Categorie"]
    X_raw = df_clf.drop(columns=["Categorie"])

    num_cols = X_raw.select_dtypes(include="number").columns.tolist()
    imp_num = SimpleImputer(strategy="median")
    X_raw[num_cols] = imp_num.fit_transform(X_raw[num_cols])

    if "Source" in X_raw.columns:
        X_raw["Source"].fillna("Unknown", inplace=True)
        X_raw = pd.get_dummies(X_raw, columns=["Source"], drop_first=False)

    le_clf = LabelEncoder()
    y_clf = le_clf.fit_transform(y_raw)

    from sklearn.model_selection import train_test_split

    _, X_test_clf, _, y_test_clf = train_test_split(
        X_raw, y_clf, test_size=0.20, random_state=42, stratify=y_clf
    )

    scaler_clf = StandardScaler()
    scaler_clf.fit(X_raw[num_cols])
    X_test_clf_s = X_test_clf.copy()
    X_test_clf_s[num_cols] = scaler_clf.transform(X_test_clf[num_cols])

    y_pred_clf = classifier.predict(X_test_clf_s)
    clf_acc = accuracy_score(y_test_clf, y_pred_clf)
    clf_f1 = f1_score(y_test_clf, y_pred_clf, average="macro")
    clf_report = classification_report(
        y_test_clf, y_pred_clf, target_names=le_clf.classes_, output_dict=True
    )
    print(f"  Accuracy: {clf_acc:.4f}  F1-macro: {clf_f1:.4f}")

    # ---- 2. Regression evaluation ----
    print("\n--- Regression (Prix_Revente) ---")
    reg_path = os.path.join(MODELS_DIR, "regressor_best.pkl")
    regressor = load_pickle(reg_path)
    print(f"  Loaded regressor from {reg_path}")

    df_reg = df.copy()
    df_reg.drop(columns=["Rapport_Collecte"], inplace=True, errors="ignore")
    df_reg.dropna(subset=["Prix_Revente"], inplace=True)

    y_reg = df_reg["Prix_Revente"].values
    X_reg = df_reg.drop(columns=["Prix_Revente"])

    num_cols_reg = X_reg.select_dtypes(include="number").columns.tolist()
    imp_reg = SimpleImputer(strategy="median")
    X_reg[num_cols_reg] = imp_reg.fit_transform(X_reg[num_cols_reg])

    cat_cols_reg = ["Categorie", "Source"]
    for c in cat_cols_reg:
        if c in X_reg.columns:
            X_reg[c].fillna("Unknown", inplace=True)
    X_reg = pd.get_dummies(
        X_reg,
        columns=[c for c in cat_cols_reg if c in X_reg.columns],
        drop_first=False,
    )

    _, X_test_reg, _, y_test_reg = train_test_split(
        X_reg, y_reg, test_size=0.20, random_state=42
    )

    scaler_reg = StandardScaler()
    scaler_reg.fit(X_reg[num_cols_reg])
    X_test_reg_s = X_test_reg.copy()
    X_test_reg_s[num_cols_reg] = scaler_reg.transform(X_test_reg[num_cols_reg])

    y_pred_reg = regressor.predict(X_test_reg_s)
    reg_rmse = float(np.sqrt(mean_squared_error(y_test_reg, y_pred_reg)))
    reg_mae = float(mean_absolute_error(y_test_reg, y_pred_reg))
    reg_r2 = float(r2_score(y_test_reg, y_pred_reg))
    print(f"  RMSE: {reg_rmse:.4f}  MAE: {reg_mae:.4f}  R²: {reg_r2:.4f}")

    # ---- 3. NLP evaluation ----
    print("\n--- NLP Classification ---")
    nlp_path = os.path.join(MODELS_DIR, "nlp", "nlp_model_best.pkl")
    nlp_info = load_pickle(nlp_path)
    nlp_model = nlp_info["classifier"]
    nlp_name = nlp_info["name"]
    print(f"  Loaded NLP model: {nlp_name}")

    # ---- 4. Clustering evaluation ----
    print("\n--- Clustering ---")
    km_path = os.path.join(MODELS_DIR, "kmeans_best.pkl")
    km_model = load_pickle(km_path)
    n_clusters = km_model.n_clusters
    print(f"  KMeans k={n_clusters}  inertia={km_model.inertia_:.1f}")

    # ---- 5. Multimodal evaluation ----
    print("\n--- Multimodal Fusion ---")
    mm_path = os.path.join(MODELS_DIR, "fusion", "multimodal_best.pkl")
    mm_info = load_pickle(mm_path)
    mm_label = mm_info["label"]
    print(f"  Best multimodal: {mm_label}")

    # ---- Build report ----
    report = {
        "classification": {
            "accuracy": round(clf_acc, 4),
            "f1_macro": round(clf_f1, 4),
            "passes_threshold": clf_acc >= min_accuracy and clf_f1 >= min_f1,
            "report": clf_report,
        },
        "regression": {
            "rmse": round(reg_rmse, 4),
            "mae": round(reg_mae, 4),
            "r2": round(reg_r2, 4),
        },
        "clustering": {
            "n_clusters": n_clusters,
            "inertia": round(float(km_model.inertia_), 2),
        },
        "nlp": {
            "model": nlp_name,
        },
        "multimodal": {
            "best_model": mm_label,
        },
        "thresholds": {
            "min_accuracy": min_accuracy,
            "min_f1": min_f1,
        },
    }

    out_path = os.path.join(REPORTS_DIR, "evaluation.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False, default=str)
    print(f"\nSaved evaluation report → {out_path}")

    # ---- MLflow ----
    tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
    mlflow.set_tracking_uri(tracking_db)
    mlflow.set_experiment("evaluation")

    with mlflow.start_run(run_name="consolidated-eval"):
        mlflow.log_metric("clf_accuracy", clf_acc)
        mlflow.log_metric("clf_f1_macro", clf_f1)
        mlflow.log_metric("reg_rmse", reg_rmse)
        mlflow.log_metric("reg_mae", reg_mae)
        mlflow.log_metric("reg_r2", reg_r2)
        mlflow.log_metric("n_clusters", n_clusters)
        mlflow.log_artifact(out_path)
        print("Logged to MLflow experiment 'evaluation'")

    # ---- Gate check ----
    if clf_acc < min_accuracy or clf_f1 < min_f1:
        print(f"\n⚠ WARNING: Classification below threshold!")
        print(f"  accuracy={clf_acc:.4f} (min={min_accuracy})")
        print(f"  f1_macro={clf_f1:.4f} (min={min_f1})")
    else:
        print(f"\n✓ All quality gates passed")

    print("evaluate stage complete ✓")


if __name__ == "__main__":
    main()
