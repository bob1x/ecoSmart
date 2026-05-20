"""
MODULE 3 -- Clustering (unsupervised)
=====================================
Features : Poids, Volume, Conductivite, Opacite, Rigidite, Prix_Revente
Pipeline : StandardScaler -> KMeans (k=2..10) -> Elbow + Silhouette
           -> optimal k -> PCA 2D scatter -> cluster interpretation
Logging  : MLflow experiment "clustering-kmeans"
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

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import mlflow
import seaborn as sns
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.impute import SimpleImputer
from sklearn.metrics import silhouette_score
from sklearn.preprocessing import StandardScaler

warnings.filterwarnings("ignore")

# ------------------------------------------------------------------ paths
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_CSV = os.path.join(ROOT, "dataset_ProjetML_2026.csv")
MODELS_DIR = os.path.join(ROOT, "models")
ART_DIR = os.path.join(MODELS_DIR, "clustering_artifacts")
os.makedirs(ART_DIR, exist_ok=True)

EXPERIMENT = "clustering-kmeans"
RANDOM_STATE = 42
K_RANGE = range(2, 11)  # k = 2 .. 10

# Numeric feature columns (unsupervised -- drop Categorie entirely)
NUM_COLS = ["Poids", "Volume", "Conductivite", "Opacite", "Rigidite", "Prix_Revente"]


# ---------------------------------------------------------- data loading
def load_and_prepare():
    """Load raw CSV, keep only numeric features, impute, scale."""
    df = pd.read_csv(RAW_CSV)

    # Keep only numeric columns
    df_num = df[NUM_COLS].copy()

    # Drop rows where ALL numeric values are NaN (useless rows)
    df_num.dropna(how="all", inplace=True)

    # Impute remaining NaNs with median
    imp = SimpleImputer(strategy="median")
    X_imputed = imp.fit_transform(df_num)
    df_num = pd.DataFrame(X_imputed, columns=NUM_COLS)

    # Scale
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(df_num)

    return df_num, X_scaled, scaler


# ---------------------------------------------- elbow + silhouette search
def search_k(X_scaled):
    """Run KMeans for k=2..10, collect inertia and silhouette scores."""
    inertias = []
    silhouettes = []
    models = {}

    for k in K_RANGE:
        km = KMeans(n_clusters=k, random_state=RANDOM_STATE, n_init=10, max_iter=300)
        labels = km.fit_predict(X_scaled)
        inertias.append(km.inertia_)
        sil = silhouette_score(X_scaled, labels)
        silhouettes.append(sil)
        models[k] = km
        print(f"  k={k:2d}  inertia={km.inertia_:12.1f}  silhouette={sil:.4f}")

    return inertias, silhouettes, models


def plot_elbow(inertias, path):
    """Save elbow (inertia) plot."""
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(list(K_RANGE), inertias, "o-", color="steelblue", linewidth=2)
    ax.set_xlabel("Number of clusters (k)")
    ax.set_ylabel("Inertia")
    ax.set_title("Elbow Method")
    ax.set_xticks(list(K_RANGE))
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)
    print(f"  Elbow plot saved -> {path}")


def plot_silhouette(silhouettes, path):
    """Save silhouette score plot."""
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(list(K_RANGE), silhouettes, "o-", color="coral", linewidth=2)
    ax.set_xlabel("Number of clusters (k)")
    ax.set_ylabel("Silhouette Score")
    ax.set_title("Silhouette Score vs k")
    ax.set_xticks(list(K_RANGE))
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)
    print(f"  Silhouette plot saved -> {path}")


# ------------------------------------------------ select optimal k
def select_optimal_k(silhouettes):
    """
    Optimal k selection strategy:
    ---------------------------------------------------------------
    We use the SILHOUETTE SCORE as the primary criterion.
    The silhouette score measures how similar a point is to its own
    cluster vs. the nearest neighboring cluster.  Higher is better
    (range: -1 to +1).

    The elbow method (inertia) is used as a secondary visual check.
    Inertia always decreases with more clusters, so we look for the
    "elbow" -- the point where adding more clusters gives diminishing
    returns.

    Decision rule:
      - Pick the k with the HIGHEST silhouette score.
      - If there is a tie or near-tie, prefer the smaller k
        (parsimony / Occam's razor).
    ---------------------------------------------------------------
    """
    sil_array = np.array(silhouettes)
    best_idx = int(np.argmax(sil_array))
    best_k = list(K_RANGE)[best_idx]
    best_sil = sil_array[best_idx]
    return best_k, best_sil


# ------------------------------------------------ PCA 2D scatter
def plot_pca_clusters(X_scaled, labels, k, path):
    """Reduce to 2D via PCA and plot clusters."""
    pca = PCA(n_components=2, random_state=RANDOM_STATE)
    X2d = pca.fit_transform(X_scaled)

    fig, ax = plt.subplots(figsize=(10, 7))
    palette = sns.color_palette("Set2", n_colors=k)
    for cluster_id in range(k):
        mask = labels == cluster_id
        ax.scatter(
            X2d[mask, 0],
            X2d[mask, 1],
            label=f"Cluster {cluster_id}",
            color=palette[cluster_id],
            alpha=0.5,
            s=12,
        )
    ax.set_xlabel(f"PC1 ({pca.explained_variance_ratio_[0]*100:.1f}% var)")
    ax.set_ylabel(f"PC2 ({pca.explained_variance_ratio_[1]*100:.1f}% var)")
    ax.set_title(f"KMeans Clusters (k={k}) -- PCA 2D projection")
    ax.legend(loc="best")
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)
    print(f"  PCA cluster plot saved -> {path}")


# -------------------------------------------- cluster interpretation
def interpret_clusters(df_num, labels, k):
    """
    For each cluster, compute mean feature values and assign a
    semantic label based on dominant characteristics.
    """
    df_work = df_num.copy()
    df_work["Cluster"] = labels

    cluster_means = df_work.groupby("Cluster")[NUM_COLS].mean()

    # Print per-cluster means
    print("\n  Mean feature values per cluster:")
    print("  " + cluster_means.to_string().replace("\n", "\n  "))

    # --- Semantic labelling heuristic ---
    # We label each cluster based on which features are notably high/low
    # relative to the overall mean.
    overall_mean = df_num[NUM_COLS].mean()
    overall_std = df_num[NUM_COLS].std()

    semantic_labels = {}
    print("\n  Cluster semantic labels:")
    for cid in range(k):
        row = cluster_means.loc[cid]
        z = (row - overall_mean) / overall_std  # z-score vs global

        descriptors = []
        # Weight
        if z["Poids"] > 0.5:
            descriptors.append("heavy")
        elif z["Poids"] < -0.5:
            descriptors.append("light")
        # Conductivity
        if z["Conductivite"] > 0.5:
            descriptors.append("high-conductivity")
        elif z["Conductivite"] < -0.3:
            descriptors.append("non-conductive")
        # Opacity
        if z["Opacite"] > 0.5:
            descriptors.append("opaque")
        elif z["Opacite"] < -0.3:
            descriptors.append("transparent")
        # Rigidity
        if z["Rigidite"] > 0.5:
            descriptors.append("rigid")
        elif z["Rigidite"] < -0.5:
            descriptors.append("flexible")
        # Volume
        if z["Volume"] > 0.5:
            descriptors.append("high-volume")
        elif z["Volume"] < -0.5:
            descriptors.append("compact")
        # Price
        if z["Prix_Revente"] > 0.5:
            descriptors.append("high-value")
        elif z["Prix_Revente"] < -0.3:
            descriptors.append("low-value")

        if not descriptors:
            descriptors = ["average-profile"]

        label = " / ".join(descriptors)
        semantic_labels[cid] = label
        print(f"    Cluster {cid}: {label}")

    return cluster_means, semantic_labels


# ================================================================ main
def main():
    import sys

    sys.stdout.reconfigure(encoding="utf-8")

    print("=" * 60)
    print("MODULE 3 - Clustering (unsupervised KMeans)")
    print("=" * 60)

    # --- data ---
    df_num, X_scaled, scaler = load_and_prepare()
    print(f"\nData: {X_scaled.shape[0]} samples, {X_scaled.shape[1]} features")
    print(f"Features: {NUM_COLS}\n")

    # --- MLflow ---
    tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
    mlflow.set_tracking_uri(tracking_db)
    mlflow.set_experiment(EXPERIMENT)

    # =================== Phase 1: search k ============================
    print("-" * 50)
    print("Phase 1 -- KMeans k=2..10 (Elbow + Silhouette)")
    print("-" * 50)
    inertias, silhouettes, km_models = search_k(X_scaled)

    # plots
    elbow_path = os.path.join(ART_DIR, "elbow_plot.png")
    plot_elbow(inertias, elbow_path)

    sil_path = os.path.join(ART_DIR, "silhouette_plot.png")
    plot_silhouette(silhouettes, sil_path)

    # =================== Phase 2: optimal k ===========================
    print("\n" + "-" * 50)
    print("Phase 2 -- Select optimal k")
    print("-" * 50)
    best_k, best_sil = select_optimal_k(silhouettes)
    print(f"  Optimal k = {best_k}  (silhouette = {best_sil:.4f})")
    print(f"  Justification: k={best_k} has the highest silhouette score")
    print(f"  among k=2..10, indicating the best-separated clusters.")

    best_km = km_models[best_k]
    labels = best_km.predict(X_scaled)

    # =================== Phase 3: PCA plot ============================
    print("\n" + "-" * 50)
    print("Phase 3 -- PCA 2D visualization")
    print("-" * 50)
    pca_path = os.path.join(ART_DIR, "pca_clusters.png")
    plot_pca_clusters(X_scaled, labels, best_k, pca_path)

    # =================== Phase 4: interpretation ======================
    print("\n" + "-" * 50)
    print("Phase 4 -- Cluster interpretation")
    print("-" * 50)
    cluster_means, semantic_labels = interpret_clusters(df_num, labels, best_k)

    # =================== Phase 5: MLflow log ==========================
    print("\n" + "-" * 50)
    print("Phase 5 -- MLflow logging")
    print("-" * 50)
    with mlflow.start_run(run_name=f"KMeans_k{best_k}"):
        mlflow.log_param("k", best_k)
        mlflow.log_param("features", ",".join(NUM_COLS))
        mlflow.log_param("scaler", "StandardScaler")
        mlflow.log_param("n_samples", X_scaled.shape[0])
        mlflow.log_metric("silhouette_score", best_sil)
        mlflow.log_metric("inertia", best_km.inertia_)

        # log all k silhouettes
        for i, k in enumerate(K_RANGE):
            mlflow.log_metric(f"silhouette_k{k}", silhouettes[i])

        # artifacts
        mlflow.log_artifact(elbow_path)
        mlflow.log_artifact(sil_path)
        mlflow.log_artifact(pca_path)

        # save model
        km_pkl = os.path.join(ART_DIR, f"kmeans_k{best_k}.pkl")
        with open(km_pkl, "wb") as f:
            pickle.dump(best_km, f)
        mlflow.log_artifact(km_pkl)

        # save cluster summary json
        summary = {
            "optimal_k": best_k,
            "silhouette_score": round(best_sil, 4),
            "inertia": round(best_km.inertia_, 2),
            "cluster_means": cluster_means.round(4).to_dict(),
            "semantic_labels": semantic_labels,
            "all_silhouettes": {
                int(k): round(s, 4) for k, s in zip(K_RANGE, silhouettes)
            },
        }
        summary_path = os.path.join(ART_DIR, "cluster_summary.json")
        with open(summary_path, "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=2, ensure_ascii=False, default=str)
        mlflow.log_artifact(summary_path)

        print(f"  Logged run to MLflow experiment '{EXPERIMENT}'")
        print(f"  Artifacts: elbow, silhouette, PCA plot, model pkl, summary json")

    print("\n" + "=" * 60)
    print("Clustering pipeline complete")
    print("=" * 60)


if __name__ == "__main__":
    main()
