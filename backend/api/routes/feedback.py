"""
api/routes/feedback.py — Feedback submission and statistics
"""

import sqlite3
from datetime import datetime, timezone

from fastapi import APIRouter

from api.models import FEEDBACK_DB
from api.schemas import FeedbackInput, FeedbackStats

router = APIRouter(tags=["feedback"])


@router.post("/feedback", status_code=201)
async def submit_feedback(fb: FeedbackInput):
    """Store a user correction for active learning."""
    is_correct = 1 if fb.predicted_label == fb.correct_label else 0
    now = datetime.now(timezone.utc).isoformat()
    conn = sqlite3.connect(FEEDBACK_DB)
    conn.execute(
        "INSERT INTO feedback (predicted_label, correct_label, is_correct, created_at) VALUES (?, ?, ?, ?)",
        (fb.predicted_label, fb.correct_label, is_correct, now),
    )
    conn.commit()
    conn.close()
    return {"status": "ok"}


@router.get("/feedback/stats", response_model=FeedbackStats)
async def feedback_stats():
    """Return aggregated feedback statistics."""
    conn = sqlite3.connect(FEEDBACK_DB)
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM feedback")
    total = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM feedback WHERE is_correct = 0")
    corrections = cur.fetchone()[0]
    cur.execute(
        "SELECT predicted_label, COUNT(*) FROM feedback WHERE is_correct = 0 GROUP BY predicted_label"
    )
    per_class = {row[0]: row[1] for row in cur.fetchall()}
    conn.close()
    accuracy = round(1.0 - (corrections / total), 4) if total > 0 else 1.0
    return FeedbackStats(
        total_feedback=total,
        corrections=corrections,
        accuracy_rate=accuracy,
        per_class=per_class,
    )
