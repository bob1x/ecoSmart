# ============================================================
# Dockerfile — Multi-stage build for Eco-Smart Classifier API
# ============================================================

# ──────────────── Stage 1: Builder ────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc g++ && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Download spaCy French model
RUN pip install --no-cache-dir --prefix=/install spacy && \
    python -m spacy download fr_core_news_md


# ──────────────── Stage 2: Runtime ────────────────
FROM python:3.11-slim AS runtime

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY api/ ./api/
COPY src/ ./src/
COPY models/ ./models/
COPY params.yaml .
COPY mlruns.db ./mlruns.db

# Create necessary directories
RUN mkdir -p reports data && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose API port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Start the API
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
