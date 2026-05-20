"""
MODULE 2 -- Supervised ML - Classification
==========================================
Target : Categorie  (Papier, Plastique, Verre, Métal)
Models : LogisticRegression, RandomForest, GradientBoosting, XGBoost, LightGBM
Tuning : Optuna (50 trials) on best 2 models
Eval   : accuracy, F1-macro, confusion matrix, classification report
Explain: SHAP TreeExplainer for best model
Logging: MLflow (params, metrics, artefacts, model registry)
"""

import json
import os
import pickle
import sys
import time
import warnings

import matplotlib
import numpy as np
import pandas as pd

matplotlib.use("Agg")  # non-interactive backend for PNG saves
import matplotlib.pyplot as plt
import mlflow
import mlflow.sklearn
import optuna
import seaborn as sns
import shap
from lightgbm import LGBMClassifier
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (accuracy_score, classification_report,
                             confusion_matrix, f1_score)
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from xgboost import XGBClassifier

warnings.filterwarnings("ignore")
optuna.logging.set_verbosity(optuna.logging.WARNING)

# ------------------------------------------------------------------ paths ---
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_CSV = os.path.join(ROOT, "dataset_ProjetML_2026.csv")
MODELS_DIR = os.path.join(ROOT, "models")
os.makedirs(MODELS_DIR, exist_ok=True)

EXPERIMENT = "classification-categorie"
REGISTRY = "waste-classifier"

RANDOM_STATE = 42
TEST_SIZE = 0.20
OPTUNA_TRIALS = 50


# ---------------------------------------------------------- data loading ---
def load_and_prepare():
    """Load raw CSV, clean, encode, scale  ->  X_train, X_test, y_train, y_test."""
    df = pd.read_csv(RAW_CSV)

    # drop free-text
    df.drop(columns=["Rapport_Collecte"], inplace=True)

    # target must exist
    df.dropna(subset=["Categorie"], inplace=True)

    # separate features / target
    y_raw = df["Categorie"]
    X_raw = df.drop(columns=["Categorie"])

    # numeric imputation (median)
    num_cols = X_raw.select_dtypes(include="number").columns.tolist()
    imp_num = SimpleImputer(strategy="median")
    X_raw[num_cols] = imp_num.fit_transform(X_raw[num_cols])

    # categorical imputation + one-hot
    if "Source" in X_raw.columns:
        X_raw["Source"].fillna("Unknown", inplace=True)
        X_raw = pd.get_dummies(X_raw, columns=["Source"], drop_first=False)

    # label encode target
    le = LabelEncoder()
    y = le.fit_transform(y_raw)
    class_names = le.classes_

    # train / test
    X_train, X_test, y_train, y_test = train_test_split(
        X_raw, y, test_size=TEST_SIZE, random_state=RANDOM_STATE, stratify=y
    )

    # scale numeric
    scaler = StandardScaler()
    X_train[num_cols] = scaler.fit_transform(X_train[num_cols])
    X_test[num_cols] = scaler.transform(X_test[num_cols])

    return X_train, X_test, y_train, y_test, class_names, le, scaler


# ------------------------------------------------ evaluation helpers ---
def evaluate(model, X_test, y_test, class_names):
    """Return dict with metrics + confusion matrix."""
    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average="macro")
    cm = confusion_matrix(y_test, y_pred)
    report = classification_report(y_test, y_pred, target_names=class_names)
    return {"accuracy": acc, "f1_macro": f1, "cm": cm, "report": report}


def save_confusion_matrix(cm, class_names, path):
    fig, ax = plt.subplots(figsize=(6, 5))
    sns.heatmap(
        cm,
        annot=True,
        fmt="d",
        cmap="Blues",
        xticklabels=class_names,
        yticklabels=class_names,
        ax=ax,
    )
    ax.set_xlabel("Predicted")
    ax.set_ylabel("Actual")
    ax.set_title("Confusion Matrix")
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)


def save_shap_plot(model, X_test, path):
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_test)
    fig = plt.figure()
    shap.summary_plot(shap_values, X_test, show=False)
    plt.tight_layout()
    plt.savefig(path, dpi=120, bbox_inches="tight")
    plt.close("all")


# ------------------------------------------------ MLflow helpers ---
def log_run(name, model, params, metrics, cm, class_names, art_dir):
    """Log a single experiment run to MLflow."""
    with mlflow.start_run(run_name=name):
        mlflow.log_params(params)
        mlflow.log_metrics(
            {
                "accuracy": metrics["accuracy"],
                "f1_macro": metrics["f1_macro"],
                "train_time": metrics.get("train_time", 0),
            }
        )
        # confusion matrix
        cm_path = os.path.join(art_dir, f"{name}_cm.png")
        save_confusion_matrix(cm, class_names, cm_path)
        mlflow.log_artifact(cm_path)
        # model pkl
        pkl_path = os.path.join(art_dir, f"{name}.pkl")
        with open(pkl_path, "wb") as f:
            pickle.dump(model, f)
        mlflow.log_artifact(pkl_path)
        # sklearn model
        mlflow.sklearn.log_model(model, artifact_path="model")
        return mlflow.active_run().info.run_id


# ---------------------------------------------- model definitions ---
def get_models():
    return {
        "LogisticRegression": LogisticRegression(
            max_iter=2000, random_state=RANDOM_STATE, n_jobs=-1
        ),
        "RandomForest": RandomForestClassifier(
            n_estimators=200, random_state=RANDOM_STATE, n_jobs=-1
        ),
        "GradientBoosting": GradientBoostingClassifier(
            n_estimators=200, random_state=RANDOM_STATE
        ),
        "XGBoost": XGBClassifier(
            n_estimators=200,
            use_label_encoder=False,
            eval_metric="mlogloss",
            random_state=RANDOM_STATE,
            n_jobs=-1,
            verbosity=0,
        ),
        "LightGBM": LGBMClassifier(
            n_estimators=200, random_state=RANDOM_STATE, n_jobs=-1, verbose=-1
        ),
    }


# ------------------------------------------------- Optuna tuning ---
def optuna_objective(trial, model_name, X_tr, y_tr):
    """Cross-val F1-macro objective for Optuna."""
    if model_name == "RandomForest":
        params = {
            "n_estimators": trial.suggest_int("n_estimators", 100, 500),
            "max_depth": trial.suggest_int("max_depth", 5, 30),
            "min_samples_split": trial.suggest_int("min_samples_split", 2, 20),
            "min_samples_leaf": trial.suggest_int("min_samples_leaf", 1, 10),
        }
        clf = RandomForestClassifier(**params, random_state=RANDOM_STATE, n_jobs=-1)
    elif model_name == "GradientBoosting":
        params = {
            "n_estimators": trial.suggest_int("n_estimators", 100, 500),
            "max_depth": trial.suggest_int("max_depth", 3, 15),
            "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.3, log=True),
            "subsample": trial.suggest_float("subsample", 0.6, 1.0),
        }
        clf = GradientBoostingClassifier(**params, random_state=RANDOM_STATE)
    elif model_name == "XGBoost":
        params = {
            "n_estimators": trial.suggest_int("n_estimators", 100, 500),
            "max_depth": trial.suggest_int("max_depth", 3, 15),
            "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.3, log=True),
            "subsample": trial.suggest_float("subsample", 0.6, 1.0),
            "colsample_bytree": trial.suggest_float("colsample_bytree", 0.5, 1.0),
        }
        clf = XGBClassifier(
            **params,
            use_label_encoder=False,
            eval_metric="mlogloss",
            random_state=RANDOM_STATE,
            n_jobs=-1,
            verbosity=0,
        )
    elif model_name == "LightGBM":
        params = {
            "n_estimators": trial.suggest_int("n_estimators", 100, 500),
            "max_depth": trial.suggest_int("max_depth", 3, 15),
            "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.3, log=True),
            "subsample": trial.suggest_float("subsample", 0.6, 1.0),
            "colsample_bytree": trial.suggest_float("colsample_bytree", 0.5, 1.0),
            "num_leaves": trial.suggest_int("num_leaves", 20, 150),
        }
        clf = LGBMClassifier(**params, random_state=RANDOM_STATE, n_jobs=-1, verbose=-1)
    else:  # LogisticRegression
        params = {
            "C": trial.suggest_float("C", 0.01, 100, log=True),
            "solver": trial.suggest_categorical("solver", ["lbfgs", "saga"]),
        }
        clf = LogisticRegression(
            **params, max_iter=2000, random_state=RANDOM_STATE, n_jobs=-1
        )

    scores = cross_val_score(clf, X_tr, y_tr, cv=5, scoring="f1_macro", n_jobs=-1)
    return scores.mean()


# ================================================================ main ===
def main():
    print("=" * 60)
    print("MODULE 2 - Classification -- Categorie")
    print("=" * 60)

    # --- data ---
    X_train, X_test, y_train, y_test, class_names, le, scaler = load_and_prepare()
    print(f"\nData  : train {X_train.shape}, test {X_test.shape}")
    print(f"Classes: {list(class_names)}\n")

    # artefact dir
    art_dir = os.path.join(MODELS_DIR, "classification_artifacts")
    os.makedirs(art_dir, exist_ok=True)

    # --- MLflow setup ---
    tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
    mlflow.set_tracking_uri(tracking_db)
    mlflow.set_experiment(EXPERIMENT)

    # =================== Phase 1: baseline comparison ===================
    print("-" * 50)
    print("Phase 1 -- Baseline comparison (default hyper-params)")
    print("-" * 50)

    models = get_models()
    results = {}
    run_ids = {}

    for name, model in models.items():
        t0 = time.time()
        model.fit(X_train, y_train)
        train_time = time.time() - t0
        metrics = evaluate(model, X_test, y_test, class_names)
        metrics["train_time"] = train_time
        results[name] = metrics

        params = model.get_params()
        # filter to loggable types
        params = {
            k: v
            for k, v in params.items()
            if isinstance(v, (int, float, str, bool, type(None)))
        }

        rid = log_run(name, model, params, metrics, metrics["cm"], class_names, art_dir)
        run_ids[name] = rid

        print(
            f"  {name:25s}  acc={metrics['accuracy']:.4f}  "
            f"f1={metrics['f1_macro']:.4f}  t={train_time:.1f}s"
        )

    # rank by f1_macro
    ranking = sorted(results.items(), key=lambda x: x[1]["f1_macro"], reverse=True)
    best2_names = [ranking[0][0], ranking[1][0]]
    print(f"\n  -> Top 2 for tuning: {best2_names}")

    # =================== Phase 2: Optuna tuning =========================
    print("\n" + "-" * 50)
    print(f"Phase 2 -- Optuna tuning ({OPTUNA_TRIALS} trials each)")
    print("-" * 50)

    tuned_models = {}
    for name in best2_names:
        print(f"  Tuning {name} ...", end="", flush=True)
        study = optuna.create_study(direction="maximize")
        study.optimize(
            lambda trial: optuna_objective(trial, name, X_train, y_train),
            n_trials=OPTUNA_TRIALS,
            n_jobs=-1,
            show_progress_bar=False,
        )
        best_params = study.best_trial.params
        print(f"  best_f1_cv={study.best_value:.4f}")

        # rebuild model with best params, train, evaluate
        if name == "RandomForest":
            clf = RandomForestClassifier(
                **best_params, random_state=RANDOM_STATE, n_jobs=-1
            )
        elif name == "GradientBoosting":
            clf = GradientBoostingClassifier(**best_params, random_state=RANDOM_STATE)
        elif name == "XGBoost":
            clf = XGBClassifier(
                **best_params,
                use_label_encoder=False,
                eval_metric="mlogloss",
                random_state=RANDOM_STATE,
                n_jobs=-1,
                verbosity=0,
            )
        elif name == "LightGBM":
            clf = LGBMClassifier(
                **best_params, random_state=RANDOM_STATE, n_jobs=-1, verbose=-1
            )
        else:
            clf = LogisticRegression(
                **best_params, max_iter=2000, random_state=RANDOM_STATE, n_jobs=-1
            )

        t0 = time.time()
        clf.fit(X_train, y_train)
        train_time = time.time() - t0
        metrics = evaluate(clf, X_test, y_test, class_names)
        metrics["train_time"] = train_time

        tuned_name = f"{name}_tuned"
        rid = log_run(
            tuned_name, clf, best_params, metrics, metrics["cm"], class_names, art_dir
        )
        tuned_models[tuned_name] = {"model": clf, "metrics": metrics, "run_id": rid}

        print(f"    acc={metrics['accuracy']:.4f}  f1={metrics['f1_macro']:.4f}")
        print(f"    params: {best_params}")

    # =================== Phase 3: best model -> SHAP + registry ==========
    print("\n" + "-" * 50)
    print("Phase 3 -- SHAP + Model Registry")
    print("-" * 50)

    # pick overall best (baseline + tuned)
    all_candidates = {n: r for n, r in results.items()}
    for n, info in tuned_models.items():
        all_candidates[n] = info["metrics"]

    best_name = max(all_candidates, key=lambda k: all_candidates[k]["f1_macro"])
    print(
        f"  Best model: {best_name}  "
        f"(f1={all_candidates[best_name]['f1_macro']:.4f})"
    )

    # get model object
    if best_name in tuned_models:
        best_model = tuned_models[best_name]["model"]
        best_rid = tuned_models[best_name]["run_id"]
    else:
        best_model = models[best_name]
        best_rid = run_ids[best_name]

    # SHAP (only for tree-based)
    tree_types = (
        RandomForestClassifier,
        GradientBoostingClassifier,
        XGBClassifier,
        LGBMClassifier,
    )
    if isinstance(best_model, tree_types):
        print("  Generating SHAP summary plot ...")
        shap_path = os.path.join(art_dir, f"{best_name}_shap.png")
        save_shap_plot(best_model, X_test, shap_path)
        # log SHAP to existing run
        with mlflow.start_run(run_id=best_rid):
            mlflow.log_artifact(shap_path)
        print(f"  Saved -> {shap_path}")
    else:
        print("  (Skipping SHAP -- best model is not tree-based)")

    # classification report
    print(f"\n  Classification report ({best_name}):")
    print(all_candidates[best_name]["report"])

    # register in MLflow Model Registry
    model_uri = f"runs:/{best_rid}/model"
    mv = mlflow.register_model(model_uri, REGISTRY)
    print(f"  Registered: {REGISTRY} v{mv.version}")

    # save best model pkl
    best_pkl = os.path.join(MODELS_DIR, "classifier_best.pkl")
    with open(best_pkl, "wb") as f:
        pickle.dump(best_model, f)
    print(f"  Saved -> {best_pkl}")

    print("\n" + "=" * 60)
    print("Classification pipeline complete OK")
    print("=" * 60)


if __name__ == "__main__":
    main()
