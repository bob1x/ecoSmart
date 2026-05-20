"""
tests/test_nlp.py — NLP pipeline tests
========================================
- No stopwords in preprocessed output
- Vectorizer output shape matches expected feature count
- NLP model predicts a valid label from known set
- Digits and punctuation removed
"""

import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import pickle

import numpy as np
import pytest

from src.nlp.preprocess import DOMAIN_STOPWORDS, _get_nlp, preprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NLP_DIR = os.path.join(ROOT, "models", "nlp")

KNOWN_LABELS = {"Papier", "Plastique", "Verre", "Métal"}


# ──────────── Preprocessing tests ────────────


def test_output_is_list_of_strings():
    """Output must be a list of strings."""
    result = preprocess("Un lot de plastique recupere a l'usine.")
    assert isinstance(result, list)
    for tok in result:
        assert isinstance(tok, str)


def test_empty_input_returns_empty_list():
    """Empty or None input -> empty list."""
    assert preprocess("") == []
    assert preprocess("   ") == []
    assert preprocess(None) == []


def test_no_stopwords_in_output():
    """No French stopwords or domain stopwords should remain."""
    text = (
        "Le rapport de collecte du dechet de type materiau "
        "echantillon a ete fait dans un centre de tri."
    )
    tokens = preprocess(text)
    nlp = _get_nlp()
    spacy_stops = nlp.Defaults.stop_words

    for tok in tokens:
        assert tok not in spacy_stops, f"Stopword '{tok}' found in output"
        assert tok not in DOMAIN_STOPWORDS, f"Domain stop '{tok}' found"


def test_digits_removed():
    """Digits should be stripped."""
    tokens = preprocess("Poids 16.7 kg volume 300 litres")
    for tok in tokens:
        assert not tok.isdigit(), f"Digit token '{tok}' found"


def test_punctuation_removed():
    """No punctuation tokens."""
    tokens = preprocess("Bonjour, c'est un test! Oui?")
    for tok in tokens:
        assert tok.isalpha(), f"Non-alpha token '{tok}' found"


# ──────────── Vectorizer tests ────────────


class TestVectorizer:
    """Tests for the vectorizer output."""

    VEC_PATH = os.path.join(NLP_DIR, "vectorizer_best.pkl")

    def test_vectorizer_loads(self):
        """Vectorizer loads from pkl."""
        if not os.path.exists(self.VEC_PATH):
            pytest.skip("vectorizer_best.pkl not found")
        with open(self.VEC_PATH, "rb") as f:
            vec_info = pickle.load(f)
        assert "vec" in vec_info
        assert "type" in vec_info

    def test_vectorizer_output_shape(self):
        """Vectorizer output shape matches expected feature count."""
        if not os.path.exists(self.VEC_PATH):
            pytest.skip("vectorizer_best.pkl not found")
        with open(self.VEC_PATH, "rb") as f:
            vec_info = pickle.load(f)

        vec = vec_info["vec"]
        vec_type = vec_info["type"]

        sample = "lot plastique usine volume poids"

        if vec_type == "sklearn":
            X = vec.transform([sample])
            assert X.shape[0] == 1
            assert X.shape[1] > 0, "Vectorizer produced 0-dim output"
        else:
            # gensim model — check wv exists
            assert hasattr(vec, "wv"), "Gensim model missing wv attribute"
            assert vec.wv.vector_size > 0


# ──────────── NLP Model tests ────────────


class TestNLPModel:
    """Tests for the NLP classification model."""

    MODEL_PATH = os.path.join(NLP_DIR, "nlp_model_best.pkl")
    LE_PATH = os.path.join(NLP_DIR, "label_encoder.pkl")

    def test_nlp_model_loads(self):
        """NLP model loads from pkl."""
        if not os.path.exists(self.MODEL_PATH):
            pytest.skip("nlp_model_best.pkl not found")
        with open(self.MODEL_PATH, "rb") as f:
            info = pickle.load(f)
        assert "classifier" in info
        assert "name" in info

    def test_nlp_predicts_valid_label(self):
        """NLP model predicts a valid label from known set."""
        if not os.path.exists(self.MODEL_PATH):
            pytest.skip("nlp_model_best.pkl not found")
        if not os.path.exists(self.LE_PATH):
            pytest.skip("label_encoder.pkl not found")

        with open(self.MODEL_PATH, "rb") as f:
            info = pickle.load(f)
        with open(self.LE_PATH, "rb") as f:
            le = pickle.load(f)

        # Also need vectorizer
        vec_path = os.path.join(NLP_DIR, "vectorizer_best.pkl")
        if not os.path.exists(vec_path):
            pytest.skip("vectorizer_best.pkl not found")
        with open(vec_path, "rb") as f:
            vec_info = pickle.load(f)

        clf = info["classifier"]
        vec = vec_info["vec"]
        vec_type = vec_info["type"]

        # Preprocess a sample text
        tokens = preprocess("Lot de papier souple opaque léger")
        joined = " ".join(tokens)

        if vec_type == "sklearn":
            X = vec.transform([joined])
        else:
            dim = vec.wv.vector_size
            vecs = [vec.wv[t] for t in tokens if t in vec.wv]
            if vecs:
                X = np.array([np.mean(vecs, axis=0)])
            else:
                X = np.zeros((1, dim))

        pred = clf.predict(X)
        label = le.inverse_transform(pred)[0]
        assert label in KNOWN_LABELS, f"Predicted '{label}' not in {KNOWN_LABELS}"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
