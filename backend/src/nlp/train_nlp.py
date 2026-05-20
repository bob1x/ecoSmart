"""
MODULE 4 -- NLP Pipeline : train_nlp.py
========================================
Takes the best vectorizer from vectorize.py, trains and compares:
  MultinomialNB (BoW/TF-IDF only), LogisticRegression, LinearSVC, RandomForest
Logs to MLflow experiment "nlp-classification".
Saves best model to models/nlp/nlp_model_best.pkl
"""

import os
import pickle
import sys
import warnings

import matplotlib
import numpy as np
import pandas as pd

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import mlflow
import mlflow.sklearn
import seaborn as sns
from scipy.sparse import issparse
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (accuracy_score, classification_report,
                             confusion_matrix, f1_score)
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import MultinomialNB
from sklearn.preprocessing import LabelEncoder
from sklearn.svm import LinearSVC

warnings.filterwarnings("ignore")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_CSV = os.path.join(ROOT, "dataset_ProjetML_2026.csv")
NLP_DIR = os.path.join(ROOT, "models", "nlp")
ART_DIR = os.path.join(NLP_DIR, "artifacts")
os.makedirs(ART_DIR, exist_ok=True)

sys.path.insert(0, ROOT)
from src.nlp.preprocess import preprocess_series

EXPERIMENT = "nlp-classification"
RANDOM_STATE = 42
TEST_SIZE = 0.20


def load_best_vectorizer():
    path = os.path.join(NLP_DIR, "vectorizer_best.pkl")
    with open(path, "rb") as f:
        return pickle.load(f)


def vectorize_texts(joined, token_lists, vec_info):
    """Transform texts using the saved vectorizer."""
    vtype = vec_info["type"]
    vec = vec_info["vec"]
    if vtype == "sklearn":
        return vec.transform(joined)
    else:
        # gensim Word2Vec or FastText - mean pool
        dim = vec.wv.vector_size
        X = []
        for tl in token_lists:
            vecs = [vec.wv[t] for t in tl if t in vec.wv]
            X.append(np.mean(vecs, axis=0) if vecs else np.zeros(dim))
        return np.array(X)


def save_cm(cm, classes, name, path):
    fig, ax = plt.subplots(figsize=(6, 5))
    sns.heatmap(
        cm,
        annot=True,
        fmt="d",
        cmap="Blues",
        xticklabels=classes,
        yticklabels=classes,
        ax=ax,
    )
    ax.set_xlabel("Predicted")
    ax.set_ylabel("Actual")
    ax.set_title(f"Confusion Matrix - {name}")
    fig.tight_layout()
    fig.savefig(path, dpi=120)
    plt.close(fig)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("MODULE 4 - NLP Classification Training")
    print("=" * 60)

    # load vectorizer info
    vec_info = load_best_vectorizer()
    vec_name = vec_info["name"]
    vec_type = vec_info["type"]
    print(f"Using vectorizer: {vec_name} ({vec_type})")

    # load data
    df = pd.read_csv(RAW_CSV)
    df.dropna(subset=["Categorie", "Rapport_Collecte"], inplace=True)
    texts = df["Rapport_Collecte"].values
    le_path = os.path.join(NLP_DIR, "label_encoder.pkl")
    with open(le_path, "rb") as f:
        le = pickle.load(f)
    y = le.transform(df["Categorie"].values)
    classes = le.classes_
    print(f"Samples: {len(texts)}  Classes: {list(classes)}\n")

    # preprocess
    print("Preprocessing texts...")
    token_lists = preprocess_series(pd.Series(texts))
    joined = [" ".join(tl) for tl in token_lists]

    # vectorize
    X = vectorize_texts(joined, token_lists, vec_info)

    # split
    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y, test_size=TEST_SIZE, random_state=RANDOM_STATE, stratify=y
    )

    # MLflow
    tracking_db = "sqlite:///" + os.path.join(ROOT, "mlruns.db").replace("\\", "/")
    mlflow.set_tracking_uri(tracking_db)
    mlflow.set_experiment(EXPERIMENT)

    # models
    is_sparse = issparse(X_tr)
    models = {}
    models["LogisticRegression"] = LogisticRegression(
        max_iter=1000, random_state=RANDOM_STATE, n_jobs=-1
    )
    models["LinearSVC"] = LinearSVC(max_iter=2000, random_state=RANDOM_STATE)
    models["RandomForest"] = RandomForestClassifier(
        n_estimators=200, random_state=RANDOM_STATE, n_jobs=-1
    )
    # MultinomialNB only works with non-negative features (BoW/TF-IDF)
    if is_sparse:
        models["MultinomialNB"] = MultinomialNB()

    results = {}
    print("-" * 50)
    for name, clf in models.items():
        clf.fit(X_tr, y_tr)
        preds = clf.predict(X_te)
        acc = accuracy_score(y_te, preds)
        f1 = f1_score(y_te, preds, average="macro")
        cm = confusion_matrix(y_te, preds)
        rep = classification_report(y_te, preds, target_names=classes)
        results[name] = {"acc": acc, "f1": f1, "cm": cm, "report": rep, "clf": clf}

        # confusion matrix png
        cm_path = os.path.join(ART_DIR, f"{name}_cm.png")
        save_cm(cm, classes, name, cm_path)

        # MLflow log
        with mlflow.start_run(run_name=name):
            mlflow.log_param("vectorizer", vec_name)
            mlflow.log_param("classifier", name)
            mlflow.log_metric("accuracy", acc)
            mlflow.log_metric("f1_macro", f1)
            mlflow.log_artifact(cm_path)
            pkl_tmp = os.path.join(ART_DIR, f"{name}.pkl")
            with open(pkl_tmp, "wb") as f:
                pickle.dump(clf, f)
            mlflow.log_artifact(pkl_tmp)

        print(f"  {name:<22s}  acc={acc:.4f}  f1={f1:.4f}")

    # best
    best_name = max(results, key=lambda k: results[k]["f1"])
    best_clf = results[best_name]["clf"]
    print(f"\nBest: {best_name}  (F1={results[best_name]['f1']:.4f})")
    print(f"\nClassification report ({best_name}):")
    print(results[best_name]["report"])

    # save best
    best_path = os.path.join(NLP_DIR, "nlp_model_best.pkl")
    with open(best_path, "wb") as f:
        pickle.dump(
            {"classifier": best_clf, "name": best_name, "vectorizer": vec_name}, f
        )
    print(f"Saved -> {best_path}")

    print("\n" + "=" * 60)
    print("NLP classification training complete")
    print("=" * 60)


if __name__ == "__main__":
    main()
