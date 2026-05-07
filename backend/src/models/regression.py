"""
MODULE 2 -- Supervised ML - Regression
======================================
Target : Prix_Revente
Models : Ridge, RandomForestRegressor, XGBRegressor, LGBMRegressor
Metrics: RMSE, MAE, R²
Logging: MLflow experiment "regression-prix"
Output : models/regressor_best.pkl
"""

import os, sys, time, warnings, pickle
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.linear_model import Ridge
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from xgboost import XGBRegressor
from lightgbm import LGBMRegressor
import mlflow
import mlflow.sklearn

warnings.filterwarnings("ignore")

# ------------------------------------------------------------------ paths ---
ROOT       = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_CSV    = os.path.join(ROOT, "dataset_ProjetML_2026.csv")
MODELS_DIR = os.path.join(ROOT, "models")
os.makedirs(MODELS_DIR, exist_ok=True)

EXPERIMENT   = "regression-prix"
RANDOM_STATE = 42
TEST_SIZE    = 0.20

# ---------------------------------------------------------- data loading ---
def load_and_prepare():
    df = pd.read_csv(RAW_CSV)

    # drop free-text
    df.drop(columns=["Rapport_Collecte"], inplace=True)

    # target must exist
    df.dropna(subset=["Prix_Revente"], inplace=True)

    y = df["Prix_Revente"].values
    X = df.drop(columns=["Prix_Revente"])

    # numeric imputation
    num_cols = X.select_dtypes(include="number").columns.tolist()
    imp = SimpleImputer(strategy="median")
    X[num_cols] = imp.fit_transform(X[num_cols])

    # categorical imputation + one-hot
    cat_cols = ["Categorie", "Source"]
    for c in cat_cols:
        if c in X.columns:
            X[c].fillna("Unknown", inplace=True)
    X = pd.get_dummies(X, columns=[c for c in cat_cols if c in X.columns],
                       drop_first=False)

    # split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=TEST_SIZE, random_state=RANDOM_STATE
    )

    # scale
    scaler = StandardScaler()
    X_train[num_cols] = scaler.fit_transform(X_train[num_cols])
    X_test[num_cols]  = scaler.transform(X_test[num_cols])

    return X_train, X_test, y_train, y_test, scaler

# ------------------------------------------------ evaluation helpers ---
def evaluate(model, X_test, y_test):
    y_pred = model.predict(X_test)
    rmse   = np.sqrt(mean_squared_error(y_test, y_pred))
    mae    = mean_absolute_error(y_test, y_pred)
    r2     = r2_score(y_test, y_pred)
    return {"rmse": rmse, "mae": mae, "r2": r2}


def save_pred_vs_actual(y_test, y_pred, name, path):
    fig, ax = plt.subplots(figsize=(6, 5))
    ax.scatter(y_test, y_pred, alpha=0.3, s=8, color="steelblue")
    mn = min(y_test.min(), y_pred.min())
    mx = max(y_test.max(), y_pred.max())
    ax.plot([mn, mx], [mn, mx], "r--", lw=1)
    ax.set_xlabel("Actual")
    ax.set_ylabel("Predicted")
    ax.set_title(f"Predicted vs Actual -- {name}")
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)

# ---------------------------------------------- model definitions ---
def get_models():
    return {
        "Ridge": Ridge(alpha=1.0, random_state=RANDOM_STATE),
        "RandomForest": RandomForestRegressor(
            n_estimators=200, random_state=RANDOM_STATE, n_jobs=-1),
        "XGBoost": XGBRegressor(
            n_estimators=200, random_state=RANDOM_STATE,
            n_jobs=-1, verbosity=0),
        "LightGBM": LGBMRegressor(
            n_estimators=200, random_state=RANDOM_STATE,
            n_jobs=-1, verbose=-1),
    }

# ================================================================ main ===
def main():
    print("=" * 60)
    print("MODULE 2 - Regression -- Prix_Revente")
    print("=" * 60)

    X_train, X_test, y_train, y_test, scaler = load_and_prepare()
    print(f"\nData  : train {X_train.shape}, test {X_test.shape}\n")

    art_dir = os.path.join(MODELS_DIR, "regression_artifacts")
    os.makedirs(art_dir, exist_ok=True)

    # MLflow
    tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
    mlflow.set_tracking_uri(tracking_db)
    mlflow.set_experiment(EXPERIMENT)

    models  = get_models()
    results = {}

    for name, model in models.items():
        t0 = time.time()
        model.fit(X_train, y_train)
        train_time = time.time() - t0

        metrics = evaluate(model, X_test, y_test)
        metrics["train_time"] = train_time
        results[name] = metrics

        # predictions plot
        y_pred = model.predict(X_test)
        plot_path = os.path.join(art_dir, f"{name}_pred_vs_actual.png")
        save_pred_vs_actual(y_test, y_pred, name, plot_path)

        # log to MLflow
        params = model.get_params()
        params = {k: v for k, v in params.items()
                  if isinstance(v, (int, float, str, bool, type(None)))}

        with mlflow.start_run(run_name=name):
            mlflow.log_params(params)
            mlflow.log_metrics({
                "rmse":       metrics["rmse"],
                "mae":        metrics["mae"],
                "r2":         metrics["r2"],
                "train_time": train_time,
            })
            mlflow.log_artifact(plot_path)
            pkl_path = os.path.join(art_dir, f"{name}.pkl")
            with open(pkl_path, "wb") as f:
                pickle.dump(model, f)
            mlflow.log_artifact(pkl_path)
            mlflow.sklearn.log_model(model, artifact_path="model")

        print(f"  {name:20s}  RMSE={metrics['rmse']:.4f}  "
              f"MAE={metrics['mae']:.4f}  R²={metrics['r2']:.4f}  "
              f"t={train_time:.1f}s")

    # pick best by R²
    best_name = max(results, key=lambda k: results[k]["r2"])
    best_model = models[best_name]
    print(f"\n  -> Best model: {best_name}  (R²={results[best_name]['r2']:.4f})")

    # save best
    best_pkl = os.path.join(MODELS_DIR, "regressor_best.pkl")
    with open(best_pkl, "wb") as f:
        pickle.dump(best_model, f)
    print(f"  Saved -> {best_pkl}")

    print("\n" + "=" * 60)
    print("Regression pipeline complete OK")
    print("=" * 60)


if __name__ == "__main__":
    main()
