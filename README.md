# EcoSmart Classifier

> Precision-clean ML pipeline + Flutter mobile app for waste material classification.

---

## Project Structure

```
Proj WHO/
├── backend/                  ← Python ML pipeline & FastAPI
│   ├── api/                  ← FastAPI app (main.py, schemas.py)
│   ├── src/
│   │   ├── data/             ← explore, clean, features scripts
│   │   ├── models/           ← classification, regression, clustering
│   │   ├── nlp/              ← NLP vectorizer & training
│   │   ├── fusion/           ← multimodal pipeline
│   │   ├── evaluation/       ← evaluation metrics
│   │   └── monitoring/       ← Evidently drift reports
│   ├── tests/                ← pytest suite (21 tests)
│   ├── data/                 ← raw & processed datasets
│   ├── models/               ← trained model artifacts (.pkl)
│   ├── grafana/              ← Grafana dashboard config
│   ├── dvc.yaml              ← 9-stage DVC pipeline
│   ├── params.yaml           ← centralised hyperparameters
│   ├── Dockerfile            ← multi-stage Docker build
│   ├── docker-compose.yml    ← API + MLflow + Prometheus + Grafana
│   ├── mlflow_setup.py       ← experiment & model registry setup
│   ├── prometheus.yml        ← Prometheus scrape config
│   └── requirements.txt
│
├── frontend/                 ← Flutter mobile app (EcoSmart)
│   ├── lib/
│   │   ├── core/theme/       ← AppColors, AppTheme, _EcoThumbShape
│   │   ├── shared/widgets/   ← HeroBar, EcoCard, CategoryBadge, etc.
│   │   ├── data/             ← models, services, repositories
│   │   └── features/         ← dashboard, prediction, nlp_assistant
│   ├── assets/icons/         ← 6 custom SVG icons
│   └── pubspec.yaml
│
├── .github/workflows/ci.yml  ← GitHub Actions CI
└── README.md
```

---

## 🚀 How to Start

### 1 — Backend (FastAPI + MLflow + Monitoring)

```bash
cd backend

# Option A: Docker Compose (recommended — starts everything)
docker-compose up --build

# Services launched:
#   API        → http://localhost:8000
#   Swagger UI → http://localhost:8000/docs
#   MLflow UI  → http://localhost:5000
#   Prometheus → http://localhost:9090
#   Grafana    → http://localhost:3000 (admin / admin)
```

```bash
# Option B: Run API locally (without Docker)
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

### 2 — ML Pipeline (DVC — optional, models already trained)

```bash
cd backend
dvc repro          # re-run all 9 pipeline stages
# or run a single stage:
python src/data/clean.py
python src/models/classification.py
```

### 3 — Frontend (Flutter Mobile App)

```bash
cd frontend

# Install dependencies
flutter pub get

# Run on Android emulator (ensure emulator is running)
flutter run

# Run on a connected device
flutter run -d <device-id>

# The app calls the API at http://10.0.2.2:8000 (Android emulator)
# For iOS simulator, change kApiBaseUrl in lib/data/services/api_service.dart
# to http://localhost:8000
```

### 4 — Run Tests

```bash
cd backend
pytest tests/ -v                    # full suite
pytest tests/test_data.py -v        # data tests only
pytest tests/test_models.py -v      # model quality tests
pytest tests/test_api.py -v         # API endpoint tests
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET`  | `/health` | Service health check |
| `POST` | `/predict/numeric` | Predict from numeric features |
| `POST` | `/predict/text` | NLP classification from report text |
| `POST` | `/predict/multimodal` | Combined numeric + text prediction |
| `GET`  | `/metrics` | Prometheus metrics |

---

## Tech Stack

| Layer | Technology |
|---|---|
| ML Pipeline | Python · scikit-learn · DVC · MLflow |
| API | FastAPI · Pydantic v2 · Uvicorn |
| Monitoring | Evidently AI · Prometheus · Grafana |
| CI/CD | GitHub Actions · Docker |
| Mobile | Flutter 3.41 · GoRouter · Provider · Hive |
