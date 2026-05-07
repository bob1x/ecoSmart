"""
DVC Stage: clean
=================
Reads raw CSV, applies imputation (type from params.yaml),
removes outliers, saves cleaned data.
Outputs: data/cleaned_data.csv
"""

import os
import sys
import warnings

import numpy as np
import pandas as pd
import yaml
from sklearn.impute import SimpleImputer, KNNImputer

warnings.filterwarnings("ignore")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RAW_CSV = os.path.join(ROOT, "dataset_ProjetML_2026.csv")
DATA_DIR = os.path.join(ROOT, "data")
os.makedirs(DATA_DIR, exist_ok=True)


def load_params():
    with open(os.path.join(ROOT, "params.yaml"), "r") as f:
        return yaml.safe_load(f)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("DVC Stage: clean — Data Cleaning & Imputation")
    print("=" * 60)

    params = load_params()
    imp_params = params["imputer"]
    imp_type = imp_params["type"]
    imp_k = imp_params.get("k", 5)

    df = pd.read_csv(RAW_CSV)
    print(f"Raw data: {df.shape[0]} rows × {df.shape[1]} cols")

    # ---- Remove outlier flag columns if they exist (from EDA notebook) ----
    outlier_cols = [c for c in df.columns if c.startswith("is_outlier")]
    if outlier_cols:
        df.drop(columns=outlier_cols, inplace=True)
        print(f"  Dropped outlier flag columns: {outlier_cols}")

    # ---- Numeric imputation ----
    num_cols = df.select_dtypes(include="number").columns.tolist()
    print(f"  Numeric cols: {num_cols}")
    print(f"  Imputer: {imp_type}" + (f" (k={imp_k})" if imp_type == "knn" else ""))

    if imp_type == "knn":
        imputer = KNNImputer(n_neighbors=imp_k)
    else:
        imputer = SimpleImputer(strategy=imp_type)

    df[num_cols] = imputer.fit_transform(df[num_cols])

    # ---- Categorical imputation ----
    cat_cols = ["Categorie", "Source"]
    for col in cat_cols:
        if col in df.columns:
            n_miss = int(df[col].isna().sum())
            if n_miss > 0:
                df[col] = df[col].fillna("Unknown")
                print(f"  Filled {n_miss} NaN in '{col}' with 'Unknown'")

    # ---- Remove rows with negative physical values ----
    physical_cols = ["Poids", "Volume", "Prix_Revente"]
    for col in physical_cols:
        if col in df.columns:
            neg_mask = df[col] < 0
            n_neg = neg_mask.sum()
            if n_neg > 0:
                df = df[~neg_mask]
                print(f"  Removed {n_neg} rows with negative {col}")

    # ---- IQR-based outlier removal for extreme values ----
    for col in num_cols:
        if col in df.columns:
            q1 = df[col].quantile(0.25)
            q3 = df[col].quantile(0.75)
            iqr = q3 - q1
            lower = q1 - 3.0 * iqr  # 3× IQR = extreme outliers only
            upper = q3 + 3.0 * iqr
            before = len(df)
            df = df[(df[col] >= lower) & (df[col] <= upper)]
            removed = before - len(df)
            if removed > 0:
                print(f"  Removed {removed} extreme outliers in '{col}'")

    df.reset_index(drop=True, inplace=True)

    # ---- Verify no NaN in numeric columns ----
    remaining_nan = df[num_cols].isna().sum().sum()
    print(f"\n  Remaining NaN in numeric cols: {remaining_nan}")

    # ---- Save ----
    out_path = os.path.join(DATA_DIR, "cleaned_data.csv")
    df.to_csv(out_path, index=False)
    print(f"\nSaved cleaned data → {out_path}")
    print(f"Final shape: {df.shape[0]} rows × {df.shape[1]} cols")
    print("clean stage complete ✓")


if __name__ == "__main__":
    main()
