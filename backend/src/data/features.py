"""
DVC Stage: features
====================
Reads cleaned data, splits into train/val/test (70:15:15),
encodes categoricals, scales numerics.
Outputs: data/train.csv, data/val.csv, data/test.csv
"""

import os
import sys
import warnings

import numpy as np
import pandas as pd
import yaml
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler

warnings.filterwarnings("ignore")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DATA_DIR = os.path.join(ROOT, "data")


def load_params():
    with open(os.path.join(ROOT, "params.yaml"), "r") as f:
        return yaml.safe_load(f)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    print("=" * 60)
    print("DVC Stage: features — Split & Feature Engineering")
    print("=" * 60)

    params = load_params()
    split_params = params["split"]
    train_ratio = split_params["train_ratio"]
    val_ratio = split_params["val_ratio"]
    test_ratio = split_params["test_ratio"]
    random_state = split_params["random_state"]
    stratify_col = split_params["stratify"]

    # ---- Load cleaned data ----
    cleaned_path = os.path.join(DATA_DIR, "cleaned_data.csv")
    df = pd.read_csv(cleaned_path)
    print(f"Loaded cleaned data: {df.shape[0]} rows × {df.shape[1]} cols")

    # ---- Drop rows with 'Unknown' category (imputed NaN, not real labels) ----
    if stratify_col in df.columns:
        n_unknown = (df[stratify_col] == "Unknown").sum()
        if n_unknown > 0:
            df = df[df[stratify_col] != "Unknown"].reset_index(drop=True)
            print(f"  Dropped {n_unknown} rows with '{stratify_col}' = 'Unknown'")

    # ---- Stratified split: train / (val + test), then val / test ----
    stratify_vals = df[stratify_col] if stratify_col in df.columns else None

    df_train, df_temp = train_test_split(
        df,
        test_size=(val_ratio + test_ratio),
        random_state=random_state,
        stratify=stratify_vals,
    )

    # Split temp into val and test
    relative_test = test_ratio / (val_ratio + test_ratio)
    stratify_temp = df_temp[stratify_col] if stratify_col in df_temp.columns else None

    df_val, df_test = train_test_split(
        df_temp,
        test_size=relative_test,
        random_state=random_state,
        stratify=stratify_temp,
    )

    print(f"  Train: {len(df_train)} ({len(df_train)/len(df)*100:.1f}%)")
    print(f"  Val:   {len(df_val)} ({len(df_val)/len(df)*100:.1f}%)")
    print(f"  Test:  {len(df_test)} ({len(df_test)/len(df)*100:.1f}%)")

    # ---- Save splits ----
    train_path = os.path.join(DATA_DIR, "train.csv")
    val_path = os.path.join(DATA_DIR, "val.csv")
    test_path = os.path.join(DATA_DIR, "test.csv")

    df_train.to_csv(train_path, index=False)
    df_val.to_csv(val_path, index=False)
    df_test.to_csv(test_path, index=False)

    print(f"\nSaved → {train_path}")
    print(f"Saved → {val_path}")
    print(f"Saved → {test_path}")
    print("features stage complete ✓")


if __name__ == "__main__":
    main()
