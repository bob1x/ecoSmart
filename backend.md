# 🧠 Backend Dissection — Eco-Smart Classifier

> This document explains **every file** in the backend, **what it does line by line**, and **how they all connect**.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [The Dataset](#2-the-dataset)
3. [Configuration — params.yaml](#3-configuration--paramsyaml)
4. [The DVC Pipeline — dvc.yaml](#4-the-dvc-pipeline--dvcyaml)
5. [Stage 1: EDA — explore.py](#5-stage-1-eda--explorepy)
6. [Stage 2: Cleaning — clean.py](#6-stage-2-cleaning--cleanpy)
7. [Stage 3: Feature Engineering — features.py](#7-stage-3-feature-engineering--featurespy)
8. [Stage 4a: Classification — classification.py](#8-stage-4a-classification--classificationpy)
9. [Stage 4b: Regression — regression.py](#9-stage-4b-regression--regressionpy)
10. [Stage 4c: Clustering — clustering.py](#10-stage-4c-clustering--clusteringpy)
11. [Stage 5: NLP Pipeline — preprocess.py → vectorize.py → train_nlp.py](#11-stage-5-nlp-pipeline)
12. [Stage 6: Multimodal Fusion — multimodal_pipeline.py](#12-stage-6-multimodal-fusion)
13. [Stage 7: Evaluation — evaluate.py](#13-stage-7-evaluation--evaluatepy)
14. [The API — api/main.py + schemas.py](#14-the-api)
15. [Infrastructure — Docker, Prometheus, Grafana](#15-infrastructure)
16. [How Everything Connects — Full Flow Diagram](#16-how-everything-connects)

---

## 1. Project Structure

```
backend/
├── dataset_ProjetML_2026.csv    ← Raw dataset (10,500 rows × 9 cols)
├── params.yaml                  ← All hyperparameters (single source of truth)
├── dvc.yaml                     ← Pipeline definition (9 stages)
│
├── src/
│   ├── data/
│   │   ├── explore.py           ← Stage 1: EDA profiling
│   │   ├── clean.py             ← Stage 2: Imputation + outlier removal
│   │   └── features.py          ← Stage 3: Train/val/test split
│   │
│   ├── models/
│   │   ├── classification.py    ← Stage 4a: Predict Categorie (5 models + Optuna)
│   │   ├── regression.py        ← Stage 4b: Predict Prix_Revente (4 models)
│   │   └── clustering.py        ← Stage 4c: KMeans k=2..10
│   │
│   ├── nlp/
│   │   ├── preprocess.py        ← Stage 5a: Text cleaning + spaCy lemmatization
│   │   ├── vectorize.py         ← Stage 5b: Compare 4 vectorizers
│   │   └── train_nlp.py         ← Stage 5c: Train classifiers on text vectors
│   │
│   ├── fusion/
│   │   └── multimodal_pipeline.py  ← Stage 6: Numeric + NLP fusion
│   │
│   ├── evaluation/
│   │   └── evaluate.py          ← Stage 7: Consolidated evaluation
│   │
│   └── monitoring/              ← (Prometheus metrics helpers)
│
├── api/
│   ├── main.py                  ← FastAPI app (3 prediction endpoints)
│   └── schemas.py               ← Pydantic input/output models
│
├── models/                      ← Saved .pkl model artifacts
├── data/                        ← Processed CSV splits (train/val/test)
├── reports/                     ← JSON evaluation reports
│
├── Dockerfile                   ← Multi-stage Docker build
├── docker-compose.yml           ← Full stack: API + MLflow + Prometheus + Grafana
├── prometheus.yml               ← Prometheus scrape config
└── requirements.txt             ← Python dependencies
```

---

## 2. The Dataset

**File:** `dataset_ProjetML_2026.csv` — 10,500 rows × 9 columns

| Column | Type | Description | Role |
|--------|------|-------------|------|
| `Poids` | float | Weight in kg | Feature |
| `Volume` | float | Volume in litres | Feature |
| `Conductivite` | float | Electrical conductivity (0-1) | Feature |
| `Opacite` | float | Opacity measurement | Feature |
| `Rigidite` | float | Rigidity score (1-10) | Feature |
| `Prix_Revente` | float | Resale price | **Target (regression)** |
| `Categorie` | string | Waste category | **Target (classification)** |
| `Source` | string | Collection source | Feature (categorical) |
| `Rapport_Collecte` | string | Free-text collection report | **Target column for NLP** |

**Categories:** Plastique (2795), Verre (2586), Papier (2318), Métal (2287)
**Sources:** Collecte_Citoyenne, Usine_A, Centre_Tri, Usine_B + 536 NaN

---

## 3. Configuration — params.yaml

**This is the single source of truth for all hyperparameters.** Every stage reads from here.

```yaml
imputer:
  type: median          # How to fill NaN in numeric columns
  k: 5                  # For KNN imputer (if type=knn)

split:
  train_ratio: 0.70     # 70% train
  val_ratio: 0.15       # 15% validation
  test_ratio: 0.15      # 15% test
  random_state: 42
  stratify: Categorie   # Keep class ratios in each split

classification:
  optuna_trials: 50     # Hyperparameter tuning trials
  models: [RandomForest, GradientBoosting, XGBoost, LightGBM, LogisticRegression]

regression:
  models: [Ridge, RandomForest, XGBoost, LightGBM]

nlp:
  max_features: 5000
  ngram_range: [1, 2]   # Unigrams + bigrams

clustering:
  k_min: 2, k_max: 10

evaluate:
  min_accuracy: 0.70    # Quality gate
  min_f1: 0.70          # Quality gate
```

---

## 4. The DVC Pipeline — dvc.yaml

DVC (Data Version Control) manages the pipeline execution order. Each stage declares its **dependencies** and **outputs**, so DVC knows what to re-run when something changes.

```
explore → clean → features → classification
                           → regression
                           → clustering
                           → train_nlp
                           → multimodal
                                        → evaluate
```

**Key point:** You run the full pipeline with `dvc repro`. DVC reads `dvc.yaml`, checks what changed, and only re-runs the affected stages.

---

## 5. Stage 1: EDA — `src/data/explore.py`

**Purpose:** Generate a statistical profile of the raw dataset.

### What it does step by step:

1. **Load** `dataset_ProjetML_2026.csv`
2. **Compute** for each column:
   - Numeric: mean, std, min, 25%, 50%, 75%, max
   - Missing values: count + percentage
   - Categorical: value_counts (top 20)
   - Correlations: Pearson correlation matrix for all numeric columns
3. **Save** everything to `reports/eda_profile.json`
4. **Log to MLflow** experiment `eda-profiling`: n_rows, n_cols, total missing cells, missing %

### Code logic:
```python
profile = {
    "describe_numeric": df[num_cols].describe(),     # summary stats
    "missing_values": count + pct per column,         # NaN analysis
    "value_counts_categorical": top 20 values,        # Categorie, Source distributions
    "correlations": df[num_cols].corr(),              # feature relationships
}
# → saves to reports/eda_profile.json
```

**You also have** `explore.ipynb` — an interactive Jupyter notebook version with plots.

---

## 6. Stage 2: Cleaning — `src/data/clean.py`

**Purpose:** Clean the raw data for all downstream models.

### What it does step by step:

1. **Read params.yaml** → get imputer type (median/mean/KNN)
2. **Load raw CSV** (10,500 rows)
3. **Numeric imputation:**
   - If `type: median` → `SimpleImputer(strategy="median")` fills NaN with column median
   - If `type: knn` → `KNNImputer(n_neighbors=5)` fills NaN using 5 nearest neighbors
4. **Categorical imputation:**
   - `Categorie` NaN → filled with `"Unknown"`
   - `Source` NaN → filled with `"Unknown"`
5. **Remove invalid rows:**
   - Rows where `Poids < 0`, `Volume < 0`, or `Prix_Revente < 0` → deleted
6. **Remove extreme outliers (3× IQR rule):**
   - For each numeric column: compute Q1, Q3, IQR = Q3 - Q1
   - Remove rows where value < Q1 - 3×IQR or value > Q3 + 3×IQR
   - Uses 3× (not 1.5×) to only remove **extreme** outliers
7. **Save** → `data/cleaned_data.csv`

### Why 3× IQR?
Standard 1.5× IQR would remove too many data points. 3× IQR only removes truly extreme values while preserving the natural distribution of waste measurements.

---

## 7. Stage 3: Feature Engineering — `src/data/features.py`

**Purpose:** Split cleaned data into train/val/test sets.

### What it does:

1. **Load** `data/cleaned_data.csv`
2. **Drop** rows where `Categorie = "Unknown"` (these were imputed NaN, not real labels)
3. **Stratified split** (preserves class ratios):
   - 70% → `data/train.csv`
   - 15% → `data/val.csv`
   - 15% → `data/test.csv`
4. Stratification column = `Categorie` (so each split has proportional Papier/Plastique/Verre/Métal)

### Note:
This stage does NOT one-hot encode or scale — that's done inside each model's training script, because different models need different preprocessing.

---

## 8. Stage 4a: Classification — `src/models/classification.py`

**Purpose:** Predict `Categorie` from numeric features.
**Target:** `Categorie` (4 classes: Métal, Papier, Plastique, Verre)

### Data preparation (inside this file):

```python
# Drop text column (not used here)
df.drop(columns=["Rapport_Collecte"])

# Numeric features: Poids, Volume, Conductivite, Opacite, Rigidite, Prix_Revente
# → Impute NaN with median
# → StandardScaler (zero mean, unit variance)

# Categorical: Source → one-hot encoded (Source_Usine_A, Source_Usine_B, etc.)

# Target: Categorie → LabelEncoder (0=Métal, 1=Papier, 2=Plastique, 3=Verre)

# Split: 80% train / 20% test (stratified)
```

### Phase 1 — Baseline comparison (5 models, default hyperparams):

| Model | What it is |
|-------|-----------|
| LogisticRegression | Linear classifier, max_iter=2000 |
| RandomForest | 200 trees, bagging ensemble |
| GradientBoosting | 200 boosted trees |
| XGBoost | Extreme gradient boosting, 200 trees |
| LightGBM | Light gradient boosting, 200 trees |

Each model: `.fit()` → `.predict()` → compute accuracy + F1-macro → log to MLflow → save confusion matrix PNG.

### Phase 2 — Optuna tuning (top 2 models):

- Takes the **2 best models** from Phase 1
- Runs **50 Optuna trials** for each, tuning:
  - `n_estimators` (100-500), `max_depth` (3-30), `learning_rate` (0.01-0.3), `subsample`, etc.
- Objective: 5-fold cross-validated F1-macro
- Rebuilds the best model with optimal params → evaluates on test set

### Phase 3 — Best model:

- Picks the overall best (baseline OR tuned) by F1-macro
- Generates **SHAP summary plot** (feature importance via game theory)
- **Registers in MLflow Model Registry** as `waste-classifier`
- Saves as `models/classifier_best.pkl`

---

## 9. Stage 4b: Regression — `src/models/regression.py`

**Purpose:** Predict `Prix_Revente` (resale price).
**Target:** `Prix_Revente` (continuous float)

### Data preparation:

```python
# Same as classification but:
# - Target = Prix_Revente (not Categorie)
# - Categorie is kept as a FEATURE (one-hot: Categorie_Métal, Categorie_Papier, etc.)
# - Source is also one-hot encoded
```

### Models compared (no Optuna here):

| Model | Metrics |
|-------|---------|
| Ridge | Linear regression with L2 regularization |
| RandomForestRegressor | 200 trees |
| XGBRegressor | 200 trees |
| LGBMRegressor | 200 trees |

**Evaluation metrics:** RMSE, MAE, R²
**Best model selected by:** highest R²
**Saves:** `models/regressor_best.pkl` + predicted-vs-actual scatter plots

---

## 10. Stage 4c: Clustering — `src/models/clustering.py`

**Purpose:** Discover natural groups in the data (unsupervised — no target column).
**Features used:** Poids, Volume, Conductivite, Opacite, Rigidite, Prix_Revente

### Pipeline:

1. **Impute** NaN with median
2. **StandardScaler** → zero mean, unit variance
3. **KMeans k=2..10** → compute inertia + silhouette score for each k
4. **Select optimal k:** highest silhouette score
5. **PCA 2D projection** → scatter plot of clusters
6. **Semantic interpretation:** for each cluster, compute z-scores of feature means vs global mean, then assign labels like "heavy / high-conductivity / high-value"

### Outputs:
- `models/kmeans_best.pkl`
- Elbow plot, silhouette plot, PCA scatter plot
- `cluster_summary.json` with means + semantic labels

---

## 11. Stage 5: NLP Pipeline

This is the **3-file chain** that processes the `Rapport_Collecte` text column.

### 5a — `src/nlp/preprocess.py` (The Foundation)

**Purpose:** Convert raw French text → clean lemmatized tokens.

```
"Lot de papier récupéré dans un site non renseigné. Poids léger de 16.7 kg"
                                    ↓
                         clean_text()
                                    ↓
"lot de papier recupere dans un site non renseigne poids leger de kg"
                                    ↓
                         spaCy tokenize + lemmatize + remove stopwords
                                    ↓
                    ["papier", "recuperer", "leger"]
```

**Step-by-step logic:**

1. `clean_text(text)`:
   - `.lower()` → all lowercase
   - `re.sub(r"[^\w\s]", " ")` → punctuation → space
   - `re.sub(r"\d+", " ")` → digits → space
   - `.strip()` → remove extra whitespace

2. `preprocess(text)`:
   - Run `clean_text()`
   - Load `fr_core_news_md` spaCy model (French, medium, with lemmatizer)
   - For each token:
     - Get `token.lemma_` (e.g., "récupéré" → "récupérer")
     - Skip if: empty, in spaCy French stopwords, in `DOMAIN_STOPWORDS`, or single char
   - **DOMAIN_STOPWORDS** = {"dechet", "collecte", "rapport", "materiau", "echantillon"} — too common in this dataset, no discriminative value

3. `preprocess_series(series)`:
   - Applies `preprocess()` to an entire pandas Series
   - Returns list of token-lists

**This function is imported by:** `vectorize.py`, `train_nlp.py`, `multimodal_pipeline.py`

---

### 5b — `src/nlp/vectorize.py` (Compare 4 Vectorizers)

**Purpose:** Find the best way to convert tokens → numbers.

Takes the tokens from `preprocess.py` and compares:

| # | Vectorizer | How it works |
|---|-----------|-------------|
| 1 | **CountVectorizer** (BoW) | Count how many times each word appears. Matrix of size [docs × 5000] |
| 2 | **TfidfVectorizer** (1,2)-grams | Like BoW but weights rare words higher. Includes bigrams ("papier_leger"). Max 5000 features |
| 3 | **Word2Vec** (gensim) | Learns 100-dim dense vectors per word. Document = mean of its word vectors |
| 4 | **FastText** (gensim) | Like Word2Vec but handles unknown words via subword info |

**Evaluation method:** Each vectorizer's output is fed into a `LogisticRegression` → compute accuracy + F1-macro on 80/20 split.

**Output:**
- Prints comparison table
- Saves the **best vectorizer** (by F1) → `models/nlp/vectorizer_best.pkl`
- Saves `label_encoder.pkl` (maps class names ↔ integers)

---

### 5c — `src/nlp/train_nlp.py` (Train Classifiers on Best Vectors)

**Purpose:** Use the best vectorizer to train multiple classifiers.

1. **Load** `vectorizer_best.pkl` from Step 5b
2. **Re-vectorize** all texts using that vectorizer
3. **Train 4 classifiers:**

| Classifier | Notes |
|-----------|-------|
| LogisticRegression | Works with any vector type |
| LinearSVC | Works with any vector type |
| RandomForest | Works with any vector type |
| MultinomialNB | **Only** if vectors are non-negative (BoW/TF-IDF, not Word2Vec) |

4. **For each:** compute accuracy, F1-macro, confusion matrix, classification_report
5. **Log each run to MLflow** experiment `nlp-classification`
6. **Save best classifier** → `models/nlp/nlp_model_best.pkl`

**The pkl contains:**
```python
{"classifier": best_clf, "name": "LinearSVC", "vectorizer": "TfidfVectorizer"}
```

---

## 12. Stage 6: Multimodal Fusion — `src/fusion/multimodal_pipeline.py`

**Purpose:** Combine numeric features + NLP text features into one mega-model.

### How fusion works:

```
                Numeric Features                     Text Features
         ┌──────────────────────────┐      ┌──────────────────────────────┐
         │ Poids, Volume, Conduc-   │      │ TF-IDF on preprocessed       │
         │ tivite, Opacite, Rigidite│      │ Rapport_Collecte             │
         │ Prix_Revente             │      │ (1,2)-grams, 5000 features   │
         │ → SimpleImputer(median)  │      │                              │
         │ → StandardScaler         │      │ Uses preprocess_series()     │
         │                          │      │ from preprocess.py           │
         │ Shape: [N, 6]            │      │ Shape: [N, 5000]             │
         └──────────┬───────────────┘      └───────────┬──────────────────┘
                    │                                   │
                    │        scipy.sparse.hstack        │
                    └──────────────┬────────────────────┘
                                  │
                     Shape: [N, 5006] (sparse matrix)
                                  │
                    ┌─────────────┴────────────┐
                    │  × NLP weight (1.0 or 2.0)│
                    └─────────────┬────────────┘
                                  │
                    Train 3 classifiers:
                    LogReg, LinearSVC, XGBoost
```

### Two strategies tested:
- **equal** (nlp_weight=1.0) — both feature sets have equal influence
- **nlp_x2** (nlp_weight=2.0) — text features are doubled

### What gets saved:
- Best model → `models/fusion/multimodal_best.pkl`
- SHAP explainability plot
- Confusion matrices for all 6 runs (3 classifiers × 2 strategies)
- Registered in MLflow as `multimodal-waste-classifier`

---

## 13. Stage 7: Evaluation — `src/evaluation/evaluate.py`

**Purpose:** Load ALL 5 best models and produce a unified report.

### What it evaluates:

| Model | Loaded from | Metrics |
|-------|-----------|---------|
| Classifier | `classifier_best.pkl` | accuracy, F1-macro |
| Regressor | `regressor_best.pkl` | RMSE, MAE, R² |
| KMeans | `kmeans_best.pkl` | n_clusters, inertia |
| NLP model | `nlp/nlp_model_best.pkl` | model name |
| Multimodal | `fusion/multimodal_best.pkl` | model label |

### Quality gate:
```python
if clf_acc < 0.70 or clf_f1 < 0.70:
    print("⚠ WARNING: Classification below threshold!")
else:
    print("✓ All quality gates passed")
```

**Output:** `reports/evaluation.json` + MLflow experiment `evaluation`

---

## 14. The API

### `api/schemas.py` — Pydantic Data Models

Defines the **exact shape** of every request and response:

**Inputs:**
```python
NumericInput:  Poids, Volume, Conductivite, Opacite, Rigidite, Source
TextInput:     rapport (free text string)
MultimodalInput: all of the above combined
```

**Outputs:**
```python
NumericOutput:    categorie, prix_revente, confidence
TextOutput:       categorie, confidence
MultimodalOutput: categorie, prix_revente, confidence, cluster_id
```

---

### `api/main.py` — FastAPI Application

**Startup:** `load_all_models()` loads all 5 .pkl files into memory.

#### Endpoint 1: `POST /predict/numeric`

**Flow:**
```
Input (Poids, Volume, etc.)
    ↓
Pass 1: _estimate_prix() → predicts Prix_Revente with uniform category prior
    ↓  (averages price across all 4 categories since we don't know category yet)
Pass 2: build_features_for_model() → creates DataFrame matching classifier's exact columns
    ↓  (includes estimated prix + one-hot Source columns)
classifier.predict_proba() → category + confidence
    ↓
Pass 3: regressor.predict() → final price with known category
    ↓
Response: {categorie, prix_revente, confidence}
```

**Why 2-pass?** The classifier was trained WITH `Prix_Revente` as a feature, but at inference time you don't know the price yet. So you estimate it first, classify, then re-predict price with the known category.

#### Endpoint 2: `POST /predict/text`

**Flow:**
```
Input (rapport text)
    ↓
preprocess_text() → lightweight regex cleanup (NO spaCy — too slow for API)
    ↓  lowercase, remove punct/digits, remove French stopwords
vectorizer.transform() → TF-IDF or Word2Vec mean-pool
    ↓
nlp_classifier.predict_proba() → category + confidence
    ↓
label_encoder.inverse_transform() → "Plastique"
    ↓
Response: {categorie, confidence}
```

**Important:** The API uses a **simplified `preprocess_text()`** function (line 232) that does NOT use spaCy. It uses regex + a hardcoded French stopword list. This is because spaCy is too heavy/slow for a production API. The training used spaCy for better quality lemmatization, but inference uses this fast approximation.

#### Endpoint 3: `POST /predict/multimodal`

Combines both: runs numeric prediction for category/price, plus uses the KMeans model to assign a cluster ID.

#### Endpoint 4: `GET /health`

Returns `{"status": "ok", "model_version": "1.0.0"}`

---

## 15. Infrastructure

### Dockerfile (Multi-stage build)

```
Stage 1 (builder): Install Python deps + spaCy French model
Stage 2 (runtime): Copy only what's needed, run as non-root user
                   CMD: uvicorn api.main:app --host 0.0.0.0 --port 8000
```

### docker-compose.yml (Full MLOps stack)

| Service | Port | Purpose |
|---------|------|---------|
| `api` | 8000 | FastAPI application |
| `mlflow` | 5000 | MLflow experiment tracking UI |
| `prometheus` | 9090 | Metrics collection (scrapes `/metrics`) |
| `grafana` | 3000 | Dashboards and visualization |

All services are on the same Docker network (`eco-net`).

The API exposes Prometheus metrics via `prometheus-fastapi-instrumentator`, which auto-instruments all endpoints with latency/count/error metrics.

---

## 16. How Everything Connects

### Full Data Flow

```
dataset_ProjetML_2026.csv (10,500 rows × 9 cols)
              │
              ├─→ explore.py → reports/eda_profile.json
              │
              ├─→ clean.py → data/cleaned_data.csv
              │       │
              │       └─→ features.py → data/train.csv, val.csv, test.csv
              │
              ├─→ classification.py ──→ models/classifier_best.pkl
              │    (drops Rapport_Collecte, uses numeric + Source)
              │
              ├─→ regression.py ──→ models/regressor_best.pkl
              │    (drops Rapport_Collecte, uses numeric + Source + Categorie)
              │
              ├─→ clustering.py ──→ models/kmeans_best.pkl
              │    (uses only 6 numeric columns)
              │
              ├─→ preprocess.py → vectorize.py → train_nlp.py
              │    (uses only Rapport_Collecte + Categorie)
              │    └──→ models/nlp/vectorizer_best.pkl
              │    └──→ models/nlp/nlp_model_best.pkl
              │    └──→ models/nlp/label_encoder.pkl
              │
              └─→ multimodal_pipeline.py ──→ models/fusion/multimodal_best.pkl
                   (uses numeric + Rapport_Collecte + Categorie)
                   (imports preprocess_series from preprocess.py)

All 5 .pkl files
        │
        └─→ evaluate.py → reports/evaluation.json (quality gate check)
        │
        └─→ api/main.py (loads all at startup, serves predictions)
                │
                └─→ Flutter frontend (calls /predict/numeric, /predict/text, etc.)
```

### MLflow Experiments

| Experiment Name | What it tracks |
|----------------|----------------|
| `eda-profiling` | Dataset stats |
| `classification-categorie` | 5 baseline + 2 tuned classifiers |
| `regression-prix` | 4 regressors |
| `clustering-kmeans` | KMeans k=2..10 silhouette/inertia |
| `nlp-classification` | NLP classifiers per vectorizer |
| `multimodal-fusion` | 6 fusion runs (2 strategies × 3 models) |
| `evaluation` | Consolidated metrics |

### Shared Code Dependencies

```
preprocess.py
    ↑ imported by:
    ├── vectorize.py      (preprocess_series)
    ├── train_nlp.py      (preprocess_series)
    └── multimodal_pipeline.py  (preprocess_series)

params.yaml
    ↑ read by:
    ├── explore.py
    ├── clean.py
    └── features.py
```

---

## Summary: What You Built

| Module | Description | Key Tech |
|--------|-------------|----------|
| **EDA** | Automated data profiling | pandas, MLflow |
| **Cleaning** | Imputation + outlier removal | sklearn Imputers, IQR |
| **Features** | Stratified train/val/test split | sklearn train_test_split |
| **Classification** | 5-model comparison + Optuna tuning + SHAP | XGBoost, LightGBM, Optuna, SHAP |
| **Regression** | 4-model comparison for price prediction | Ridge, RF, XGB, LGBM |
| **Clustering** | Unsupervised grouping with interpretation | KMeans, PCA, Silhouette |
| **NLP** | Text → tokens → vectors → classify | spaCy, TF-IDF, Word2Vec, FastText |
| **Multimodal** | Fuse numeric + text features | scipy.sparse.hstack, XGBoost |
| **Evaluation** | Quality gates + consolidated report | min_accuracy, min_f1 |
| **API** | 3 prediction endpoints + health check | FastAPI, Pydantic, Uvicorn |
| **MLOps** | Experiment tracking + monitoring | MLflow, Prometheus, Grafana, Docker |
| **Deployment** | Containerized multi-service stack | Docker, docker-compose |
