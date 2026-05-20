"""
api/metrics_tracker.py — In-memory API metrics (no external Prometheus needed)

Tracks request count, latency, errors per endpoint. Lightweight, self-contained.
Data resets on server restart (by design — production would use persistent storage).
"""

import time
from collections import defaultdict
from threading import Lock
from typing import Any, Dict, List

_lock = Lock()

# ── Counters ──
_total_requests: int = 0
_total_errors: int = 0
_latencies: List[float] = []  # last 1000 request latencies in ms
_per_endpoint: Dict[str, int] = defaultdict(int)
_start_time: float = time.time()

MAX_LATENCY_HISTORY = 1000


def record_request(path: str, latency_ms: float, is_error: bool = False) -> None:
    """Record a single API request."""
    global _total_requests, _total_errors
    with _lock:
        _total_requests += 1
        if is_error:
            _total_errors += 1
        _per_endpoint[path] += 1
        _latencies.append(latency_ms)
        if len(_latencies) > MAX_LATENCY_HISTORY:
            _latencies.pop(0)


def get_stats() -> Dict[str, Any]:
    """Return current API statistics."""
    with _lock:
        total = _total_requests
        errors = _total_errors
        lats = list(_latencies)

    if not lats:
        avg_lat = 0.0
        p95_lat = 0.0
    else:
        avg_lat = round(sum(lats) / len(lats), 1)
        sorted_lats = sorted(lats)
        p95_idx = int(len(sorted_lats) * 0.95)
        p95_lat = round(sorted_lats[min(p95_idx, len(sorted_lats) - 1)], 1)

    error_rate = round((errors / total) * 100, 2) if total > 0 else 0.0
    uptime_s = round(time.time() - _start_time)

    # Build latency trend (last 20 buckets for sparkline)
    trend = []
    if lats:
        bucket_size = max(1, len(lats) // 20)
        for i in range(0, len(lats), bucket_size):
            bucket = lats[i : i + bucket_size]
            trend.append(round(sum(bucket) / len(bucket), 1))
        trend = trend[-20:]  # keep last 20 points

    return {
        "total_requests": total,
        "total_errors": errors,
        "avg_latency_ms": avg_lat,
        "p95_latency_ms": p95_lat,
        "error_rate_pct": error_rate,
        "uptime_seconds": uptime_s,
        "latency_trend": trend if trend else [0],
        "per_endpoint": dict(_per_endpoint),
    }
