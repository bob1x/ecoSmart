"""
DVC Stage: explore
===================
Generates EDA profiling statistics from the raw CSV.
Outputs: reports/eda_profile.json
Logs to MLflow experiment 'eda-profiling'.
"""

import json
import os
import sys
import warnings

import mlflow
import numpy as np
import pandas as pd
import yaml

warnings.filterwarnings("ignore")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_CSV = os.path.join(ROOT, "dataset_ProjetML_2026.csv")
REPORTS_DIR = os.path.join(ROOT, "reports")
os.makedirs(REPORTS_DIR, exist_ok=True)


def load_params():
    with open(os.path.join(ROOT, "params.yaml"), "r") as f:
        return yaml.safe_load(f)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("DVC Stage: explore — EDA Profiling")
    print("=" * 60)

    params = load_params()
    df = pd.read_csv(RAW_CSV)
    print(f"Loaded {df.shape[0]} rows × {df.shape[1]} cols")

    num_cols = df.select_dtypes(include="number").columns.tolist()
    cat_cols = df.select_dtypes(include="object").columns.tolist()

    # --- Build profile ---
    profile = {
        "shape": {"rows": df.shape[0], "cols": df.shape[1]},
        "dtypes": {c: str(df[c].dtype) for c in df.columns},
        "numeric_columns": num_cols,
        "categorical_columns": cat_cols,
        "describe_numeric": {},
        "missing_values": {},
        "value_counts_categorical": {},
        "correlations": {},
    }

    # Numeric statistics
    desc = df[num_cols].describe().to_dict()
    profile["describe_numeric"] = {
        col: {k: round(v, 6) for k, v in stats.items()} for col, stats in desc.items()
    }

    # Missing values
    for col in df.columns:
        n_miss = int(df[col].isna().sum())
        profile["missing_values"][col] = {
            "count": n_miss,
            "pct": round(n_miss / len(df) * 100, 2),
        }

    # Categorical value counts (top 20)
    for col in cat_cols:
        vc = df[col].value_counts().head(20).to_dict()
        profile["value_counts_categorical"][col] = {
            str(k): int(v) for k, v in vc.items()
        }

    # Correlation matrix
    corr = df[num_cols].corr()
    profile["correlations"] = {
        col: {c: round(v, 4) for c, v in row.items()}
        for col, row in corr.to_dict().items()
    }

    # --- Save ---
    out_path = os.path.join(REPORTS_DIR, "eda_profile.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(profile, f, indent=2, ensure_ascii=False, default=str)
    print(f"Saved profile → {out_path}")

    # --- MLflow ---
    tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
    mlflow.set_tracking_uri(tracking_db)
    mlflow.set_experiment("eda-profiling")

    with mlflow.start_run(run_name="eda-profile"):
        mlflow.log_param("n_rows", df.shape[0])
        mlflow.log_param("n_cols", df.shape[1])
        mlflow.log_param("num_features", len(num_cols))
        mlflow.log_param("cat_features", len(cat_cols))
        total_missing = int(df.isna().sum().sum())
        mlflow.log_metric("total_missing_cells", total_missing)
        mlflow.log_metric(
            "missing_pct", round(total_missing / (df.shape[0] * df.shape[1]) * 100, 2)
        )
        mlflow.log_artifact(out_path)
        print("Logged to MLflow experiment 'eda-profiling'")

    print("explore stage complete ✓")


if __name__ == "__main__":
    main()
