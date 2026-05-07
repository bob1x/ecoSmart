"""
MODULE 4 -- NLP Pipeline : vectorize.py
========================================
Compare 4 vectorisation approaches on Rapport_Collecte -> Categorie:
  1. CountVectorizer (BoW)
  2. TfidfVectorizer (1,2)-grams
  3. Word2Vec  (gensim, mean-pool)
  4. FastText  (gensim, mean-pool, handles OOV)
Each evaluated via LogisticRegression accuracy + F1-macro.
Best vectorizer saved to models/nlp/vectorizer_best.pkl
"""

import os, sys, warnings, pickle, time
import numpy as np
import pandas as pd

from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score, f1_score
from gensim.models import Word2Vec, FastText as FTModel

warnings.filterwarnings("ignore")

# -- paths
ROOT       = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_CSV    = os.path.join(ROOT, "dataset_ProjetML_2026.csv")
NLP_DIR    = os.path.join(ROOT, "models", "nlp")
os.makedirs(NLP_DIR, exist_ok=True)

# add project root so we can import src.nlp.preprocess
sys.path.insert(0, ROOT)
from src.nlp.preprocess import preprocess_series

RANDOM_STATE = 42
TEST_SIZE    = 0.20


# ------------------------------------------------ data
def load_data():
    df = pd.read_csv(RAW_CSV)
    df.dropna(subset=["Categorie", "Rapport_Collecte"], inplace=True)
    texts  = df["Rapport_Collecte"].values
    labels = df["Categorie"].values
    return texts, labels


# ----------------------------------------------- gensim helpers
def mean_pool(model, tokens, dim):
    """Mean-pool word vectors for a document."""
    vecs = []
    for t in tokens:
        if t in model.wv:
            vecs.append(model.wv[t])
    if not vecs:
        return np.zeros(dim)
    return np.mean(vecs, axis=0)


def build_gensim_vectors(token_lists, ModelClass, dim=100, window=5, min_count=2):
    """Train gensim model and return document matrix."""
    model = ModelClass(
        sentences=token_lists, vector_size=dim,
        window=window, min_count=min_count, workers=-1, seed=RANDOM_STATE
    )
    X = np.array([mean_pool(model, tl, dim) for tl in token_lists])
    return X, model


# ================================================================ main
def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("MODULE 4 - Vectorization comparison")
    print("=" * 60)

    texts, labels = load_data()
    le = LabelEncoder()
    y  = le.fit_transform(labels)
    print(f"Samples: {len(texts)}  Classes: {list(le.classes_)}\n")

    # preprocess all texts
    print("Preprocessing texts with spaCy (may take a minute)...")
    token_lists = preprocess_series(pd.Series(texts))
    joined      = [" ".join(tl) for tl in token_lists]  # for sklearn vectorizers

    # train/test split (indices)
    idx = np.arange(len(texts))
    idx_tr, idx_te, y_tr, y_te = train_test_split(
        idx, y, test_size=TEST_SIZE, random_state=RANDOM_STATE, stratify=y
    )

    results = {}

    # ---- 1. CountVectorizer (BoW) ----
    print("\n1. CountVectorizer (BoW)...")
    cv = CountVectorizer(max_features=5000)
    Xcv = cv.fit_transform(joined)
    lr1 = LogisticRegression(max_iter=1000, random_state=RANDOM_STATE, n_jobs=-1)
    lr1.fit(Xcv[idx_tr], y_tr)
    p1 = lr1.predict(Xcv[idx_te])
    results["CountVectorizer"] = {
        "acc": accuracy_score(y_te, p1),
        "f1":  f1_score(y_te, p1, average="macro"),
        "vec": cv, "model": lr1, "type": "sklearn",
    }

    # ---- 2. TfidfVectorizer ----
    print("2. TfidfVectorizer (1,2)-grams...")
    tv = TfidfVectorizer(ngram_range=(1, 2), max_features=5000)
    Xtv = tv.fit_transform(joined)
    lr2 = LogisticRegression(max_iter=1000, random_state=RANDOM_STATE, n_jobs=-1)
    lr2.fit(Xtv[idx_tr], y_tr)
    p2 = lr2.predict(Xtv[idx_te])
    results["TfidfVectorizer"] = {
        "acc": accuracy_score(y_te, p2),
        "f1":  f1_score(y_te, p2, average="macro"),
        "vec": tv, "model": lr2, "type": "sklearn",
    }

    # ---- 3. Word2Vec (mean-pool) ----
    print("3. Word2Vec (gensim, dim=100)...")
    tl_tr = [token_lists[i] for i in idx_tr]
    Xw2v_full, w2v_model = build_gensim_vectors(token_lists, Word2Vec)
    lr3 = LogisticRegression(max_iter=1000, random_state=RANDOM_STATE, n_jobs=-1)
    lr3.fit(Xw2v_full[idx_tr], y_tr)
    p3 = lr3.predict(Xw2v_full[idx_te])
    results["Word2Vec"] = {
        "acc": accuracy_score(y_te, p3),
        "f1":  f1_score(y_te, p3, average="macro"),
        "vec": w2v_model, "model": lr3, "type": "gensim",
    }

    # ---- 4. FastText (mean-pool) ----
    print("4. FastText (gensim, dim=100)...")
    Xft_full, ft_model = build_gensim_vectors(token_lists, FTModel)
    lr4 = LogisticRegression(max_iter=1000, random_state=RANDOM_STATE, n_jobs=-1)
    lr4.fit(Xft_full[idx_tr], y_tr)
    p4 = lr4.predict(Xft_full[idx_te])
    results["FastText"] = {
        "acc": accuracy_score(y_te, p4),
        "f1":  f1_score(y_te, p4, average="macro"),
        "vec": ft_model, "model": lr4, "type": "gensim",
    }

    # ---- comparison table ----
    print("\n" + "=" * 60)
    print(f"{'Method':<22s} {'Accuracy':>10s} {'F1-macro':>10s}")
    print("-" * 44)
    for name, r in results.items():
        print(f"  {name:<20s} {r['acc']:>9.4f}  {r['f1']:>9.4f}")
    print("=" * 60)

    # ---- save best ----
    best_name = max(results, key=lambda k: results[k]["f1"])
    best_info = results[best_name]
    print(f"\nBest: {best_name}  (F1={best_info['f1']:.4f})")

    pkl_path = os.path.join(NLP_DIR, "vectorizer_best.pkl")
    with open(pkl_path, "wb") as f:
        pickle.dump({
            "name":  best_name,
            "type":  best_info["type"],
            "vec":   best_info["vec"],
            "model": best_info["model"],
        }, f)
    print(f"Saved -> {pkl_path}")

    # also save label encoder
    le_path = os.path.join(NLP_DIR, "label_encoder.pkl")
    with open(le_path, "wb") as f:
        pickle.dump(le, f)

    print("\nVectorization comparison complete")


if __name__ == "__main__":
    main()
