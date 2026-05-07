"""
MODULE 5 -- Multimodal Fusion
==============================
Combines numeric features + NLP (TF-IDF on Rapport_Collecte) into a
single feature matrix, then trains LogisticRegression, LinearSVC, XGBoost.
Two weighting strategies: equal weight vs NLP x2.0.
Logs best to MLflow as "multimodal-waste-classifier".
SHAP summary plot for best model.
"""

import os, sys, warnings, pickle, time
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns

from scipy.sparse import hstack, csr_matrix
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.impute import SimpleImputer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.svm import LinearSVC
from sklearn.metrics import (accuracy_score, f1_score,
                             confusion_matrix, classification_report)
from xgboost import XGBClassifier
import shap
import mlflow, mlflow.sklearn

warnings.filterwarnings("ignore")

ROOT     = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_CSV  = os.path.join(ROOT, "dataset_ProjetML_2026.csv")
MOD_DIR  = os.path.join(ROOT, "models", "fusion")
ART_DIR  = os.path.join(MOD_DIR, "artifacts")
os.makedirs(ART_DIR, exist_ok=True)

sys.path.insert(0, ROOT)
from src.nlp.preprocess import preprocess_series

EXPERIMENT   = "multimodal-fusion"
REGISTRY     = "multimodal-waste-classifier"
RANDOM_STATE = 42
TEST_SIZE    = 0.20
NUM_COLS     = ["Poids", "Volume", "Conductivite", "Opacite", "Rigidite", "Prix_Revente"]


# -------------------------------------------------------- data
def load_data():
    df = pd.read_csv(RAW_CSV)
    df.dropna(subset=["Categorie", "Rapport_Collecte"], inplace=True)
    return df


def prepare_features(df):
    """Build numeric matrix + TF-IDF text matrix."""
    # --- numeric pipeline ---
    X_num = df[NUM_COLS].copy()
    imp = SimpleImputer(strategy="median")
    X_num = pd.DataFrame(imp.fit_transform(X_num), columns=NUM_COLS,
                         index=df.index)
    scaler = StandardScaler()
    X_num_scaled = scaler.fit_transform(X_num)

    # --- text pipeline ---
    print("  Preprocessing texts with spaCy...")
    token_lists = preprocess_series(df["Rapport_Collecte"])
    joined = [" ".join(tl) for tl in token_lists]
    tfidf = TfidfVectorizer(ngram_range=(1, 2), max_features=5000)
    X_text = tfidf.fit_transform(joined)

    # --- target ---
    le = LabelEncoder()
    y = le.fit_transform(df["Categorie"].values)

    return X_num_scaled, X_text, y, le, scaler, tfidf


def fuse(X_num, X_text, nlp_weight=1.0):
    """hstack numeric (dense->sparse) + text (sparse), with optional weight."""
    X_num_sp = csr_matrix(X_num)
    X_text_w = X_text * nlp_weight
    return hstack([X_num_sp, X_text_w])


def save_cm(cm, classes, name, path):
    fig, ax = plt.subplots(figsize=(6, 5))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
                xticklabels=classes, yticklabels=classes, ax=ax)
    ax.set_xlabel("Predicted"); ax.set_ylabel("Actual")
    ax.set_title(f"Confusion Matrix - {name}")
    fig.tight_layout(); fig.savefig(path, dpi=120); plt.close(fig)


def save_shap_plot(model, X, path):
    """SHAP for the best model. Convert sparse to dense if needed."""
    X_dense = X.toarray() if hasattr(X, "toarray") else np.array(X)
    # subsample for speed
    if X_dense.shape[0] > 500:
        idx = np.random.RandomState(RANDOM_STATE).choice(
            X_dense.shape[0], 500, replace=False)
        X_dense = X_dense[idx]
    explainer = shap.Explainer(model, X_dense)
    shap_values = explainer(X_dense)
    fig = plt.figure()
    shap.summary_plot(shap_values, X_dense, show=False, max_display=20)
    plt.tight_layout()
    plt.savefig(path, dpi=120, bbox_inches="tight")
    plt.close("all")


# ============================================================ main
def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("MODULE 5 - Multimodal Fusion Pipeline")
    print("=" * 60)

    df = load_data()
    X_num, X_text, y, le, scaler, tfidf = prepare_features(df)
    classes = le.classes_
    print(f"  Samples: {len(y)}  Classes: {list(classes)}")
    print(f"  Numeric features: {X_num.shape[1]}")
    print(f"  Text features   : {X_text.shape[1]}")

    # MLflow
    tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
    mlflow.set_tracking_uri(tracking_db)
    mlflow.set_experiment(EXPERIMENT)

    # two weighting strategies
    strategies = {
        "equal":   1.0,
        "nlp_x2":  2.0,
    }

    all_results = {}

    for strat_name, weight in strategies.items():
        print(f"\n{'=' * 50}")
        print(f"Strategy: {strat_name}  (NLP weight = {weight})")
        print("=" * 50)

        X_fused = fuse(X_num, X_text, nlp_weight=weight)
        X_tr, X_te, y_tr, y_te = train_test_split(
            X_fused, y, test_size=TEST_SIZE,
            random_state=RANDOM_STATE, stratify=y
        )

        models = {
            "LogisticRegression": LogisticRegression(
                max_iter=1000, random_state=RANDOM_STATE, n_jobs=-1),
            "LinearSVC": LinearSVC(
                max_iter=2000, random_state=RANDOM_STATE),
            "XGBoost": XGBClassifier(
                n_estimators=200, use_label_encoder=False,
                eval_metric="mlogloss", random_state=RANDOM_STATE,
                n_jobs=-1, verbosity=0),
        }

        for name, clf in models.items():
            t0 = time.time()
            clf.fit(X_tr, y_tr)
            tt = time.time() - t0
            preds = clf.predict(X_te)
            acc = accuracy_score(y_te, preds)
            f1  = f1_score(y_te, preds, average="macro")
            cm  = confusion_matrix(y_te, preds)

            run_label = f"{strat_name}_{name}"
            all_results[run_label] = {
                "clf": clf, "acc": acc, "f1": f1, "cm": cm,
                "strat": strat_name, "weight": weight,
                "X_te": X_te, "y_te": y_te,
            }

            # confusion matrix png
            cm_path = os.path.join(ART_DIR, f"{run_label}_cm.png")
            save_cm(cm, classes, run_label, cm_path)

            # MLflow
            with mlflow.start_run(run_name=run_label):
                mlflow.log_param("strategy", strat_name)
                mlflow.log_param("nlp_weight", weight)
                mlflow.log_param("classifier", name)
                mlflow.log_param("num_features", X_num.shape[1])
                mlflow.log_param("text_features", X_text.shape[1])
                mlflow.log_metric("accuracy", acc)
                mlflow.log_metric("f1_macro", f1)
                mlflow.log_metric("train_time", tt)
                mlflow.log_artifact(cm_path)

            print(f"  {run_label:<35s}  acc={acc:.4f}  f1={f1:.4f}  t={tt:.1f}s")

    # ---- best overall ----
    best_label = max(all_results, key=lambda k: all_results[k]["f1"])
    best = all_results[best_label]
    print(f"\n{'=' * 60}")
    print(f"Best: {best_label}  (F1={best['f1']:.4f})")

    # classification report
    rep = classification_report(best["y_te"],
                                best["clf"].predict(best["X_te"]),
                                target_names=classes)
    print(rep)

    # SHAP
    print("Generating SHAP summary plot (may take a moment)...")
    shap_path = os.path.join(ART_DIR, f"{best_label}_shap.png")
    try:
        save_shap_plot(best["clf"], best["X_te"], shap_path)
        print(f"  SHAP plot saved -> {shap_path}")
    except Exception as e:
        print(f"  SHAP plot skipped ({e})")
        shap_path = None

    # register best in MLflow
    with mlflow.start_run(run_name=f"BEST_{best_label}"):
        mlflow.log_param("strategy", best["strat"])
        mlflow.log_param("nlp_weight", best["weight"])
        mlflow.log_param("best_classifier", best_label)
        mlflow.log_metric("accuracy", best["acc"])
        mlflow.log_metric("f1_macro", best["f1"])
        if shap_path and os.path.exists(shap_path):
            mlflow.log_artifact(shap_path)
        mlflow.sklearn.log_model(best["clf"], artifact_path="model")
        rid = mlflow.active_run().info.run_id

    model_uri = f"runs:/{rid}/model"
    mv = mlflow.register_model(model_uri, REGISTRY)
    print(f"Registered: {REGISTRY} v{mv.version}")

    # save pkl
    best_pkl = os.path.join(MOD_DIR, "multimodal_best.pkl")
    with open(best_pkl, "wb") as f:
        pickle.dump({"clf": best["clf"], "label": best_label,
                      "weight": best["weight"]}, f)
    print(f"Saved -> {best_pkl}")

    print("\n" + "=" * 60)
    print("Multimodal fusion pipeline complete")
    print("=" * 60)


if __name__ == "__main__":
    main()
