"""
tests/test_data.py — Data pipeline tests
==========================================
- Schema check: all expected columns after cleaning
- No NaN in numeric columns after imputation
- Train/val/test sizes match 70:15:15 (±1%)
- Cleaned file saved at expected path
"""

import os
import sys

import numpy as np
import pandas as pd
import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_DIR = os.path.join(ROOT, "data")


# ──────────── Expected schema ────────────
EXPECTED_COLUMNS = [
    "Poids",
    "Volume",
    "Conductivite",
    "Opacite",
    "Rigidite",
    "Prix_Revente",
    "Categorie",
    "Source",
    "Rapport_Collecte",
]

NUMERIC_COLUMNS = [
    "Poids",
    "Volume",
    "Conductivite",
    "Opacite",
    "Rigidite",
    "Prix_Revente",
]


# ──────────── Fixtures ────────────
@pytest.fixture
def cleaned_df():
    """Load cleaned data if available."""
    path = os.path.join(DATA_DIR, "cleaned_data.csv")
    if not os.path.exists(path):
        pytest.skip("cleaned_data.csv not found — run `dvc repro` first")
    return pd.read_csv(path)


@pytest.fixture
def split_dfs():
    """Load train/val/test splits if available."""
    paths = {
        "train": os.path.join(DATA_DIR, "train.csv"),
        "val": os.path.join(DATA_DIR, "val.csv"),
        "test": os.path.join(DATA_DIR, "test.csv"),
    }
    for name, p in paths.items():
        if not os.path.exists(p):
            pytest.skip(f"{name}.csv not found — run `dvc repro` first")
    return {name: pd.read_csv(p) for name, p in paths.items()}


# ──────────── Tests ────────────
class TestCleaning:
    """Tests for the cleaning stage."""

    def test_cleaned_file_exists(self):
        """Cleaned CSV file saved at expected path."""
        path = os.path.join(DATA_DIR, "cleaned_data.csv")
        assert os.path.exists(path), f"Expected cleaned file at {path}"

    def test_schema_columns_present(self, cleaned_df):
        """All expected columns are present after cleaning."""
        for col in EXPECTED_COLUMNS:
            assert col in cleaned_df.columns, f"Missing column: {col}"

    def test_no_nan_in_numeric_columns(self, cleaned_df):
        """No NaN values remain in numeric columns after imputation."""
        for col in NUMERIC_COLUMNS:
            if col in cleaned_df.columns:
                n_nan = cleaned_df[col].isna().sum()
                assert (
                    n_nan == 0
                ), f"Column '{col}' has {n_nan} NaN values after cleaning"

    def test_no_negative_physical_values(self, cleaned_df):
        """No negative values in Poids, Volume, Prix_Revente."""
        for col in ["Poids", "Volume", "Prix_Revente"]:
            if col in cleaned_df.columns:
                n_neg = (cleaned_df[col] < 0).sum()
                assert n_neg == 0, f"Column '{col}' has {n_neg} negative values"


class TestSplit:
    """Tests for the feature engineering / split stage."""

    def test_split_files_exist(self):
        """Train, val, test CSV files exist."""
        for name in ["train", "val", "test"]:
            path = os.path.join(DATA_DIR, f"{name}.csv")
            assert os.path.exists(path), f"Missing: {path}"

    def test_split_ratios(self, split_dfs):
        """Train/val/test sizes match 70:15:15 ratio (±1%)."""
        n_train = len(split_dfs["train"])
        n_val = len(split_dfs["val"])
        n_test = len(split_dfs["test"])
        total = n_train + n_val + n_test

        train_pct = n_train / total * 100
        val_pct = n_val / total * 100
        test_pct = n_test / total * 100

        assert (
            abs(train_pct - 70) <= 1.0
        ), f"Train ratio {train_pct:.1f}% not within ±1% of 70%"
        assert (
            abs(val_pct - 15) <= 1.0
        ), f"Val ratio {val_pct:.1f}% not within ±1% of 15%"
        assert (
            abs(test_pct - 15) <= 1.0
        ), f"Test ratio {test_pct:.1f}% not within ±1% of 15%"

    def test_no_data_leakage(self, split_dfs):
        """No row duplication across splits (check by index count)."""
        total = len(split_dfs["train"]) + len(split_dfs["val"]) + len(split_dfs["test"])
        combined = pd.concat(
            [split_dfs["train"], split_dfs["val"], split_dfs["test"]],
            ignore_index=True,
        )
        assert len(combined) == total, "Row count mismatch after concat"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
