"""
api/routes/prometheus.py — Query Prometheus for real time-series metrics.

Falls back to in-memory metrics_tracker when Prometheus is unavailable.
"""

import os
import time
from datetime import datetime, timedelta

import httpx
from fastapi import APIRouter

from api.metrics_tracker import get_stats as get_inmemory_stats

router = APIRouter(tags=["mlops"])

# Prometheus URL — inside docker-compose network it's "prometheus:9090"
# Externally (dev) it's localhost:9088
PROM_URL = os.getenv("PROMETHEUS_URL", "http://prometheus:9090")


async def _prom_query(query: str) -> list:
    """Execute a PromQL instant query, return the result vector."""
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            r = await client.get(f"{PROM_URL}/api/v1/query", params={"query": query})
            data = r.json()
            if data.get("status") == "success":
                return data["data"]["result"]
    except Exception:
        pass
    return []


async def _prom_range(query: str, minutes: int = 30, step: str = "60s") -> list:
    """Execute a PromQL range query over the last N minutes."""
    try:
        now = time.time()
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get(
                f"{PROM_URL}/api/v1/query_range",
                params={
                    "query": query,
                    "start": now - (minutes * 60),
                    "end": now,
                    "step": step,
                },
            )
            data = r.json()
            if data.get("status") == "success":
                return data["data"]["result"]
    except Exception:
        pass
    return []


@router.get("/mlops/prometheus-metrics")
async def prometheus_metrics():
    """Return real Prometheus metrics for the Flutter dashboard.

    Queries Prometheus for time-series data. Falls back to
    in-memory stats when Prometheus is not available.
    """
    prom_available = False

    # ── 1. Request rate over time (last 30 min, 1-min steps) ──
    request_rate_series = []
    rate_result = await _prom_range(
        "sum(rate(http_requests_total[2m]))", minutes=30, step="60s"
    )
    if rate_result:
        prom_available = True
        for series in rate_result:
            points = [
                {"t": int(v[0]), "v": round(float(v[1]), 3)}
                for v in series.get("values", [])
            ]
            request_rate_series.append(
                {
                    "label": series.get("metric", {}).get("handler", "total"),
                    "points": points,
                }
            )

    # ── 2. p95 latency over time ──
    latency_series = []
    lat_result = await _prom_range(
        "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[2m])) by (le))",
        minutes=30,
        step="60s",
    )
    if lat_result:
        for series in lat_result:
            points = [
                {"t": int(v[0]), "v": round(float(v[1]) * 1000, 1)}  # sec → ms
                for v in series.get("values", [])
                if v[1] != "NaN"
            ]
            latency_series.append({"label": "p95", "points": points})

    # ── 3. Requests per endpoint (pie chart data) ──
    endpoint_breakdown = []
    ep_result = await _prom_query("sum by (handler) (http_requests_total)")
    if ep_result:
        for item in ep_result:
            handler = item["metric"].get("handler", "unknown")
            count = int(float(item["value"][1]))
            if count > 0 and handler not in ("/metrics",):
                endpoint_breakdown.append(
                    {
                        "endpoint": handler,
                        "count": count,
                    }
                )
        endpoint_breakdown.sort(key=lambda x: -x["count"])

    # ── 4. Total requests & error rate (instant) ──
    total_requests = 0
    total_result = await _prom_query("sum(http_requests_total)")
    if total_result:
        total_requests = int(float(total_result[0]["value"][1]))

    error_count = 0
    err_result = await _prom_query('sum(http_requests_total{status=~"[45].."})')
    if err_result:
        error_count = int(float(err_result[0]["value"][1]))

    error_rate = (
        round((error_count / total_requests * 100), 2) if total_requests > 0 else 0
    )

    # ── 5. Uptime ──
    uptime_seconds = 0
    up_result = await _prom_query("process_start_time_seconds")
    if up_result:
        start_ts = float(up_result[0]["value"][1])
        uptime_seconds = int(time.time() - start_ts)

    # ── Fallback to in-memory if Prometheus unavailable ──
    fallback_stats = {}
    if not prom_available:
        fallback_stats = get_inmemory_stats()

    return {
        "prometheus_available": prom_available,
        "request_rate_series": request_rate_series,
        "latency_series": latency_series,
        "endpoint_breakdown": endpoint_breakdown,
        "total_requests": (
            total_requests
            if prom_available
            else fallback_stats.get("total_requests", 0)
        ),
        "error_rate_pct": (
            error_rate if prom_available else fallback_stats.get("error_rate_pct", 0)
        ),
        "uptime_seconds": (
            uptime_seconds
            if prom_available
            else fallback_stats.get("uptime_seconds", 0)
        ),
        "fallback_stats": fallback_stats if not prom_available else {},
        "generated_at": datetime.now().isoformat(),
    }
