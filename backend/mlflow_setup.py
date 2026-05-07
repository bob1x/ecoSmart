"""
mlflow_setup.py
================
1. Creates 5 named experiments in MLflow.
2. Sets tracking URI to ./mlruns (SQLite backend).
3. Registers best model from each experiment in Model Registry.
"""

import os
import sys
import warnings

import mlflow
from mlflow.tracking import MlflowClient

warnings.filterwarnings("ignore")

ROOT = os.path.abspath(os.path.dirname(__file__))
TRACKING_DB = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")

EXPERIMENTS = [
    "eda-profiling",
    "classification",
    "regression-prix",
    "nlp-classification",
    "multimodal",
]

# Mapping: experiment name → registered model name
REGISTRY_MAP = {
    "classification": "waste-classifier",
    "classification-categorie": "waste-classifier",
    "regression-prix": "waste-regressor",
    "nlp-classification": "nlp-waste-classifier",
    "multimodal": "multimodal-waste-classifier",
    "multimodal-fusion": "multimodal-waste-classifier",
}


def setup_experiments(client):
    """Create experiments if they don't exist."""
    for name in EXPERIMENTS:
        exp = client.get_experiment_by_name(name)
        if exp is None:
            eid = client.create_experiment(name)
            print(f"  Created experiment: '{name}' (id={eid})")
        else:
            print(f"  Experiment exists:  '{name}' (id={exp.experiment_id})")


def register_best_models(client):
    """Find best run in each experiment and register in Model Registry."""
    for exp_name, model_name in REGISTRY_MAP.items():
        exp = client.get_experiment_by_name(exp_name)
        if exp is None:
            print(f"  ⚠ Experiment '{exp_name}' not found — skipping")
            continue

        # Search runs sorted by metric
        if "regression" in exp_name:
            metric_key = "r2"
            order = "DESC"
        elif "clustering" in exp_name:
            metric_key = "silhouette_score"
            order = "DESC"
        else:
            metric_key = "f1_macro"
            order = "DESC"

        runs = client.search_runs(
            experiment_ids=[exp.experiment_id],
            order_by=[f"metrics.{metric_key} {order}"],
            max_results=1,
        )

        if not runs:
            print(f"  ⚠ No runs in '{exp_name}' — skipping registration")
            continue

        best_run = runs[0]
        run_id = best_run.info.run_id
        metric_val = best_run.data.metrics.get(metric_key, "N/A")

        # Check if run has a logged model
        model_uri = f"runs:/{run_id}/model"
        try:
            mv = mlflow.register_model(model_uri, model_name)
            print(
                f"  Registered '{model_name}' v{mv.version} "
                f"from '{exp_name}' ({metric_key}={metric_val})"
            )
        except Exception as e:
            print(f"  ⚠ Could not register from '{exp_name}': {e}")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("MLflow Setup — Experiments & Model Registry")
    print("=" * 60)

    mlflow.set_tracking_uri(TRACKING_DB)
    client = MlflowClient(tracking_uri=TRACKING_DB)

    print(f"\nTracking URI: {TRACKING_DB}")

    # Step 1: Create experiments
    print("\n--- Creating experiments ---")
    setup_experiments(client)

    # Step 2: Register best models
    print("\n--- Registering best models ---")
    register_best_models(client)

    print("\n" + "=" * 60)
    print("MLflow setup complete ✓")
    print("=" * 60)


if __name__ == "__main__":
    main()
