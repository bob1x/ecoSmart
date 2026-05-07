"""
api/schemas.py — Pydantic v2 models for all API endpoints
==========================================================
"""

from typing import Optional
from pydantic import BaseModel, Field


# ──────────────────────────── Inputs ────────────────────────────


class NumericInput(BaseModel):
    """Input schema for numeric prediction (classification + regression)."""

    Poids: float = Field(
        ...,
        description="Weight of the waste sample in kg",
        examples=[47.28],
        ge=0,
    )
    Volume: float = Field(
        ...,
        description="Volume of the waste sample in litres",
        examples=[64.70],
        ge=0,
    )
    Conductivite: float = Field(
        ...,
        description="Electrical conductivity (0 to 1)",
        examples=[0.0],
        ge=0,
        le=1,
    )
    Opacite: float = Field(
        ...,
        description="Opacity measurement",
        examples=[1.0],
        ge=0,
    )
    Rigidite: float = Field(
        ...,
        description="Rigidity score (1-10 scale)",
        examples=[3.0],
        ge=1,
        le=10,
    )
    Source: str = Field(
        ...,
        description="Collection source (e.g. Usine_A, Usine_B, Centre_Tri)",
        examples=["Usine_A"],
    )


class TextInput(BaseModel):
    """Input schema for text-based prediction."""

    rapport: str = Field(
        ...,
        description="Free-text collection report (Rapport_Collecte)",
        examples=[
            "Lot de papier récupéré dans un site non renseigné. "
            "Poids léger de 16.7 kg, volume moyen."
        ],
        min_length=5,
    )


class MultimodalInput(BaseModel):
    """Input schema for multimodal prediction (numeric + text)."""

    Poids: float = Field(..., examples=[47.28], ge=0)
    Volume: float = Field(..., examples=[64.70], ge=0)
    Conductivite: float = Field(..., examples=[0.0], ge=0, le=1)
    Opacite: float = Field(..., examples=[1.0], ge=0)
    Rigidite: float = Field(..., examples=[3.0], ge=1, le=10)
    Source: str = Field(..., examples=["Usine_A"])
    rapport: str = Field(
        ...,
        description="Free-text collection report",
        examples=["Lot plastique à l'Usine A. Volume 64.7 L, poids 47.3 kg."],
        min_length=5,
    )


# ──────────────────────────── Outputs ───────────────────────────


class NumericOutput(BaseModel):
    """Output schema for numeric prediction."""

    categorie: str = Field(
        ...,
        description="Predicted waste category",
        examples=["Plastique"],
    )
    prix_revente: float = Field(
        ...,
        description="Predicted resale price",
        examples=[4.73],
    )
    confidence: float = Field(
        ...,
        description="Prediction confidence (0-1)",
        examples=[0.92],
        ge=0,
        le=1,
    )


class TextOutput(BaseModel):
    """Output schema for text prediction."""

    categorie: str = Field(
        ...,
        description="Predicted waste category from text",
        examples=["Papier"],
    )
    confidence: float = Field(
        ...,
        description="Prediction confidence (0-1)",
        examples=[0.87],
        ge=0,
        le=1,
    )


class MultimodalOutput(BaseModel):
    """Output schema for multimodal prediction."""

    categorie: str = Field(..., examples=["Plastique"])
    prix_revente: float = Field(..., examples=[4.73])
    confidence: float = Field(..., examples=[0.91], ge=0, le=1)
    cluster_id: int = Field(
        ...,
        description="Assigned cluster from KMeans",
        examples=[2],
        ge=0,
    )


class HealthResponse(BaseModel):
    """Health check response."""

    status: str = Field(..., examples=["ok"])
    model_version: str = Field(
        ...,
        description="Version string of the deployed models",
        examples=["1.0.0"],
    )
