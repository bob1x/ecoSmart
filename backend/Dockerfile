# ============================================================
# Dockerfile — Eco-Smart Classifier API + Flutter Web
# ============================================================
# Unified deployment: serves both API and frontend from one container.

FROM python:3.11-slim

WORKDIR /app

# Install system deps for numpy/scikit-learn
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc g++ && \
    rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY api/ ./api/
COPY models/classifier_best.pkl ./models/classifier_best.pkl
COPY models/regressor_best.pkl ./models/regressor_best.pkl
COPY models/kmeans_best.pkl ./models/kmeans_best.pkl
COPY models/nlp/nlp_model_best.pkl ./models/nlp/nlp_model_best.pkl
COPY models/nlp/vectorizer_best.pkl ./models/nlp/vectorizer_best.pkl
COPY models/nlp/label_encoder.pkl ./models/nlp/label_encoder.pkl
COPY models/fusion/multimodal_best.pkl ./models/fusion/multimodal_best.pkl

# Copy Flutter web build (static files)
COPY static/ ./static/

# Expose port (Render sets $PORT dynamically)
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Start — uses $PORT from Render, defaults to 8000
CMD uvicorn api.main:app --host 0.0.0.0 --port ${PORT:-8000}
