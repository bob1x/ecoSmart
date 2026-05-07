"""
MODULE 4 -- NLP Pipeline : preprocess.py
=========================================
Text preprocessing for Rapport_Collecte column.
- lowercase, remove punctuation/digits/extra whitespace
- tokenize with spaCy (fr_core_news_md)
- remove French stopwords + domain-specific stopwords
- lemmatize
"""

import re, warnings
import spacy

warnings.filterwarnings("ignore")

# Domain-specific stopwords to remove on top of spaCy defaults
DOMAIN_STOPWORDS = {"dechet", "collecte", "rapport", "materiau", "echantillon"}

# Load French model (lazy singleton)
_nlp = None

def _get_nlp():
    global _nlp
    if _nlp is None:
        _nlp = spacy.load("fr_core_news_md", disable=["ner", "parser"])
    return _nlp


def clean_text(text):
    """Lowercase, strip punctuation, digits, extra whitespace."""
    if not isinstance(text, str) or not text.strip():
        return ""
    text = text.lower()
    text = re.sub(r"[^\w\s]", " ", text)   # punctuation -> space
    text = re.sub(r"\d+", " ", text)        # digits -> space
    text = re.sub(r"\s+", " ", text).strip()
    return text


def preprocess(text):
    """
    Full preprocessing pipeline for a single document.
    Returns a list of clean lemmatised tokens (strings).
    """
    cleaned = clean_text(text)
    if not cleaned:
        return []

    nlp = _get_nlp()
    doc = nlp(cleaned)

    # spaCy built-in French stopwords
    spacy_stops = nlp.Defaults.stop_words

    tokens = []
    for token in doc:
        lemma = token.lemma_.lower().strip()
        # skip if empty, stopword, single char, or domain stopword
        if (not lemma
                or lemma in spacy_stops
                or lemma in DOMAIN_STOPWORDS
                or len(lemma) <= 1):
            continue
        tokens.append(lemma)

    return tokens


def preprocess_series(series):
    """Apply preprocess() to a pandas Series. Returns list of token-lists."""
    return [preprocess(text) for text in series.fillna("")]


# ---- quick smoke test when run directly ----
if __name__ == "__main__":
    import sys; sys.stdout.reconfigure(encoding="utf-8")
    sample = (
        "Lot de papier recupere dans un site non renseigne. "
        "Poids leger de 16.7 kg, volume moyen. "
        "Materiau souple, non conducteur, aspect tres opaque."
    )
    tokens = preprocess(sample)
    print("Input :", sample)
    print("Tokens:", tokens)
    print("Count :", len(tokens))
