"""
api/routes/export.py — CSV and PDF export endpoints
"""

import csv
import io
import json
import sqlite3
from datetime import datetime

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from api.models import (CATEGORIES, FEEDBACK_DB, MODEL_VERSION, RECYCLABILITY,
                        models)

router = APIRouter(tags=["export"])


@router.get("/export/feedback")
async def export_feedback_csv():
    """Export all feedback data as a downloadable CSV."""
    conn = sqlite3.connect(FEEDBACK_DB)
    cur = conn.cursor()
    cur.execute(
        "SELECT id, predicted_label, correct_label, is_correct, created_at "
        "FROM feedback ORDER BY id"
    )
    rows = cur.fetchall()
    conn.close()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(
        ["id", "predicted_label", "correct_label", "is_correct", "created_at"]
    )
    for row in rows:
        writer.writerow(row)

    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=ecosmart_feedback.csv"},
    )


@router.get("/export/report")
async def export_pdf_report():
    """Generate a comprehensive PDF performance report."""
    try:
        from fpdf import FPDF
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="fpdf2 not installed. Run: pip install fpdf2",
        )

    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=15)

    # ── Page 1: Title + Overview ──
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 24)
    pdf.cell(0, 15, "EcoSmart Classifier", ln=True, align="C")
    pdf.set_font("Helvetica", "", 12)
    pdf.cell(0, 8, "Performance Report", ln=True, align="C")
    pdf.cell(
        0,
        8,
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        ln=True,
        align="C",
    )
    pdf.ln(10)

    # Model overview
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "1. Model Overview", ln=True)

    model_info = [
        ("Model Version", MODEL_VERSION),
        ("Categories", ", ".join(CATEGORIES)),
        ("Classifier", type(models.get("classifier", "N/A")).__name__),
        ("Regressor", type(models.get("regressor", "N/A")).__name__),
        (
            "NLP Model",
            type(models.get("nlp_info", {}).get("classifier", "N/A")).__name__,
        ),
    ]

    for label, value in model_info:
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(60, 7, f"  {label}:", ln=False)
        pdf.set_font("Helvetica", "", 10)
        pdf.cell(0, 7, str(value), ln=True)

    pdf.ln(8)

    # ── Feature importances ──
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "2. Feature Importances (RandomForest)", ln=True)

    clf = models.get("classifier")
    clf_feats = models.get("clf_features")
    if hasattr(clf, "feature_importances_") and clf_feats:
        importances = clf.feature_importances_
        pairs = sorted(zip(clf_feats, importances), key=lambda x: -x[1])
        pdf.set_font("Helvetica", "B", 9)
        pdf.cell(80, 7, "Feature", border=1, ln=False, align="C")
        pdf.cell(50, 7, "Importance", border=1, ln=True, align="C")
        pdf.set_font("Helvetica", "", 9)
        for feat, imp in pairs[:15]:
            display = feat.replace("Categorie_", "Cat: ").replace("Source_", "Src: ")
            pdf.cell(80, 6, f"  {display}", border=1, ln=False)
            pdf.cell(50, 6, f"  {imp:.4f}", border=1, ln=True)
    else:
        pdf.set_font("Helvetica", "", 10)
        pdf.cell(
            0, 7, "  Feature importances not available for this model type.", ln=True
        )

    pdf.ln(6)

    # ── Feedback statistics ──
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "3. User Feedback Statistics", ln=True)

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

    accuracy = round((1.0 - (corrections / total)) * 100, 1) if total > 0 else 100.0

    pdf.set_font("Helvetica", "", 10)
    pdf.cell(0, 7, f"  Total feedback entries: {total}", ln=True)
    pdf.cell(0, 7, f"  Corrections: {corrections}", ln=True)
    pdf.cell(0, 7, f"  User-validated accuracy: {accuracy}%", ln=True)

    if per_class:
        pdf.ln(4)
        pdf.set_font("Helvetica", "B", 9)
        pdf.cell(80, 7, "Class", border=1, ln=False, align="C")
        pdf.cell(50, 7, "Corrections", border=1, ln=True, align="C")
        pdf.set_font("Helvetica", "", 9)
        for cls, cnt in sorted(per_class.items()):
            pdf.cell(80, 6, f"  {cls}", border=1, ln=False)
            pdf.cell(50, 6, f"  {cnt}", border=1, ln=True)

    pdf.ln(8)

    # ── EcoScore formula ──
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "4. EcoScore Formula", ln=True)
    pdf.set_font("Helvetica", "", 10)
    pdf.multi_cell(
        0,
        6,
        "EcoScore = clamp(recyclability_weight x confidence x 80 + min(|price| / 20, 20), 0, 100)\n"
        f"Recyclability weights: {json.dumps(RECYCLABILITY)}",
    )

    # Output
    buf = io.BytesIO()
    pdf.output(buf)
    buf.seek(0)

    return StreamingResponse(
        buf,
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=ecosmart_report.pdf"},
    )
