"""
src/monitoring/drift_report.py — Data & model drift detection
==============================================================
1. Loads reference data (train set) and current data (test set)
2. Evidently AI: DataDriftPreset + DataQualityPreset
3. Jensen-Shannon divergence on text length distribution
4. Saves HTML report to reports/drift_report.html
5. Logs drift metrics to MLflow
"""

import json
import os
import sys
import warnings

import mlflow
import numpy as np
import pandas as pd
import yaml
from scipy.spatial.distance import jensenshannon

warnings.filterwarnings("ignore")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DATA_DIR = os.path.join(ROOT, "data")
REPORTS_DIR = os.path.join(ROOT, "reports")
os.makedirs(REPORTS_DIR, exist_ok=True)

NUM_COLS = ["Poids", "Volume", "Conductivite", "Opacite", "Rigidite", "Prix_Revente"]


def load_params():
    with open(os.path.join(ROOT, "params.yaml"), "r") as f:
        return yaml.safe_load(f)


def compute_text_length_js_divergence(ref_texts, cur_texts, n_bins=50):
    """
    Compute Jensen-Shannon divergence between text-length distributions.
    """
    ref_lens = ref_texts.str.len().dropna().values
    cur_lens = cur_texts.str.len().dropna().values

    if len(ref_lens) == 0 or len(cur_lens) == 0:
        return 0.0

    # Create common bins
    all_lens = np.concatenate([ref_lens, cur_lens])
    bins = np.linspace(all_lens.min(), all_lens.max(), n_bins + 1)

    ref_hist, _ = np.histogram(ref_lens, bins=bins, density=True)
    cur_hist, _ = np.histogram(cur_lens, bins=bins, density=True)

    # Add small epsilon to avoid division by zero
    eps = 1e-10
    ref_hist = ref_hist + eps
    cur_hist = cur_hist + eps

    # Normalise to probability distributions
    ref_hist = ref_hist / ref_hist.sum()
    cur_hist = cur_hist / cur_hist.sum()

    js_div = float(jensenshannon(ref_hist, cur_hist))
    return js_div


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("Monitoring — Drift Report")
    print("=" * 60)

    # ---- Load reference (train) and current (test) data ----
    train_path = os.path.join(DATA_DIR, "train.csv")
    test_path = os.path.join(DATA_DIR, "test.csv")

    if not os.path.exists(train_path) or not os.path.exists(test_path):
        print("⚠ train.csv / test.csv not found. Run `dvc repro` first.")
        sys.exit(1)

    ref_data = pd.read_csv(train_path)
    cur_data = pd.read_csv(test_path)
    print(f"Reference (train): {ref_data.shape}")
    print(f"Current   (test):  {cur_data.shape}")

    # ---- Evidently AI Reports ----
    drift_results = {}

    try:
        from evidently.metric_preset import DataDriftPreset, DataQualityPreset
        from evidently.report import Report

        # Numeric columns only for drift
        num_cols_present = [
            c for c in NUM_COLS if c in ref_data.columns and c in cur_data.columns
        ]

        print("\n--- DataDriftPreset ---")
        drift_report = Report(metrics=[DataDriftPreset()])
        drift_report.run(
            reference_data=ref_data[num_cols_present],
            current_data=cur_data[num_cols_present],
        )

        drift_html_path = os.path.join(REPORTS_DIR, "drift_report.html")
        drift_report.save_html(drift_html_path)
        print(f"  Saved drift report → {drift_html_path}")

        # Extract drift results
        drift_dict = drift_report.as_dict()
        if "metrics" in drift_dict:
            for metric in drift_dict["metrics"]:
                result = metric.get("result", {})
                if "drift_by_columns" in result:
                    for col, info in result["drift_by_columns"].items():
                        drift_results[col] = {
                            "drift_detected": info.get("drift_detected", False),
                            "stattest_name": info.get("stattest_name", ""),
                            "drift_score": round(info.get("drift_score", 0), 4),
                        }

        print("\n--- DataQualityPreset ---")
        quality_report = Report(metrics=[DataQualityPreset()])
        quality_report.run(
            reference_data=ref_data[num_cols_present],
            current_data=cur_data[num_cols_present],
        )

        quality_html_path = os.path.join(REPORTS_DIR, "quality_report.html")
        quality_report.save_html(quality_html_path)
        print(f"  Saved quality report → {quality_html_path}")

    except ImportError:
        print("  ⚠ Evidently not installed — skipping Evidently reports")
        print("    Install: pip install evidently")
    except Exception as e:
        print(f"  ⚠ Evidently error: {e}")

    # ---- Jensen-Shannon divergence on text length ----
    print("\n--- Text Length JS Divergence ---")
    text_col = "Rapport_Collecte"
    if text_col in ref_data.columns and text_col in cur_data.columns:
        js_div = compute_text_length_js_divergence(
            ref_data[text_col], cur_data[text_col]
        )
        print(f"  JS divergence (text length): {js_div:.6f}")
        drift_results["text_length_js_divergence"] = round(js_div, 6)
    else:
        print(f"  ⚠ Column '{text_col}' not found in data")

    # ---- Save JSON summary ----
    summary = {
        "reference_shape": list(ref_data.shape),
        "current_shape": list(cur_data.shape),
        "drift_results": drift_results,
    }
    summary_path = os.path.join(REPORTS_DIR, "drift_summary.json")
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, ensure_ascii=False, default=str)
    print(f"\nDrift summary → {summary_path}")

    # ---- MLflow logging ----
    tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
    mlflow.set_tracking_uri(tracking_db)
    mlflow.set_experiment("monitoring-drift")

    with mlflow.start_run(run_name="drift-report"):
        # Log per-column drift scores
        for col, info in drift_results.items():
            if isinstance(info, dict) and "drift_score" in info:
                mlflow.log_metric(f"drift_{col}", info["drift_score"])
                if info.get("drift_detected"):
                    mlflow.log_metric(f"drift_detected_{col}", 1)

        # Log JS divergence
        if "text_length_js_divergence" in drift_results:
            mlflow.log_metric(
                "text_length_js_divergence",
                drift_results["text_length_js_divergence"],
            )

        # Log artifacts
        if os.path.exists(os.path.join(REPORTS_DIR, "drift_report.html")):
            mlflow.log_artifact(os.path.join(REPORTS_DIR, "drift_report.html"))
        if os.path.exists(os.path.join(REPORTS_DIR, "quality_report.html")):
            mlflow.log_artifact(os.path.join(REPORTS_DIR, "quality_report.html"))
        mlflow.log_artifact(summary_path)

        print("Logged drift metrics to MLflow ✓")

    print("\n" + "=" * 60)
    print("Drift report complete ✓")
    print("=" * 60)


if __name__ == "__main__":
    main()
