# PROMPTS.md — Journal des Prompts IA (TP7 NLP)

## Prompt 1 — Pipeline de Prétraitement
**Objectif :** Créer une pipeline NLP pour nettoyer la colonne `Rapport_Collecte`
**Prompt :** "Créer un pipeline de preprocessing NLP en Python pour du texte français : lowercase, suppression ponctuation/chiffres, tokenisation avec spaCy (fr_core_news_md), suppression stopwords + stopwords domaine, lemmatisation."
**Résultat :** Fonctions `clean_text()` et `preprocess()` dans `preprocess.py`

## Prompt 2 — Comparaison Vectorisations
**Objectif :** Comparer TF-IDF, CountVectorizer, Word2Vec, FastText
**Prompt :** "Comparer 4 méthodes de vectorisation (BoW, TF-IDF, Word2Vec, FastText) sur un corpus français avec évaluation par LogisticRegression."
**Résultat :** Script `vectorize.py` avec tableau comparatif

## Prompt 3 — Classification Multi-Modèles
**Objectif :** Entraîner et comparer plusieurs classifieurs
**Prompt :** "Entraîner MultinomialNB, LogisticRegression, LinearSVC, RandomForest sur les vecteurs NLP, logger dans MLflow, sauvegarder le meilleur modèle."
**Résultat :** Script `train_nlp.py` avec MLflow tracking

## Prompt 4 — Extraction d'Attributs Regex
**Objectif :** Extraire contamination, état matériau, source depuis le texte
**Prompt :** "Extraire 3 attributs depuis des rapports de collecte en français via regex : contamination (binaire), état du matériau (neuf/moyen/brisé), source mentionnée."
**Résultat :** Cellule 2.2 du notebook TP7

## Prompt 5 — Fusion Multimodale
**Objectif :** Combiner features numériques + NLP pour prédire Prix_Revente
**Prompt :** "Créer un modèle de fusion multimodale combinant features numériques et TF-IDF pour prédire une variable continue, comparer avec modèle numérique seul."
**Résultat :** Cellule 2.3 du notebook TP7
