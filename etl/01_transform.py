""" 
Stage 1 - Transform
Hospital Readmission Reporting & Utilization Analysis

Reads the raw diabetic_data.csv and applies all cleaning/design decisions documented in /docs/data_profiling_and_cleaning_decisions.md, 
producing clean, load-ready CSVs for each target table:

    output/patients.csv
    output/encounters.csv
    output/diagnoses.csv
    output/medications.csv

These CSVs are the input to Stage 2 (02_load_mysql.py), which loads them intpo the MySQL schema defined in /schema/01_schema/sql.

Run: 
    python 01_transform.py
"""

import pandas as pd

RAW_CSV_PATH = "../data/raw/diabetic_data.csv"
OUTPUT_DIR = "../data/processed"


# ICD-9 -> clinical category mapping (Strack et al., 2014, Table 2)
def map_icd9_category(code):
    if pd.isna(code) or code == "Unknown" or code == "?":
        return "Unknown"
    code = str(code).strip()

    # V and E codes (external causes / supplemental classification) -> Other 
    if code.startswith("V") or code.startswith("E"):
        return "Other"

    try:
        val = float(code)
    except ValueError:
        return "Other"

    if 250 <= val < 251:
        return "Diabetes"
    if (390 <= val <= 459) or val == 785:
        return "Circulatory"
    if (460 <= val <= 519) or val == 786:
        return "Respiratory"
    if (520 <= val <= 579) or val == 787:
        return "Digestive"
    if (800 <= val <= 999):
        return "Injury"
    if (710 <= val <= 739):
        return "Musculoskeletal"
    if (580 <= val <= 629) or val == 799:
        return "Genitourinary"
    if (140 <= val <= 239):
        return "Neoplasms"
    return "Other"

# Mode with first occurence tiebreak resolver for race/gender 
def resolve_mode_first(series):
    counts = series.value_counts()
    max_count = counts.max()
    candidates = set(counts[counts == max_count].index)
    if len(candidates) == 1:
        return next(iter(candidates))
    # tie-break = first occurrence in og (encounter) order
    for val in series: 
        if val in candidates:
            return val
    return series.iloc[0] # fallback, should not be reached 

def main():
    df = pd.read_csv(RAW_CSV_PATH, dtype=str, keep_default_na=False, na_values=[])

    print(f"Raw shape: {df.shape}")

    # 1. Drop zero-varaince / near-fully-missing columns
    df = df.drop(columns=["weight", "examide", "citoglipton"])

    # 2. Drop invalid gender rows
    df = df[df["gender"] != "Unknown/Invalid"].copy()

    # 3. Recode '?' -> 'Unknown' on relevant columns
    unknown_recode_cols = ["race", "medical_specialty", "payer_code", "diag_1", "diag_2", "diag_3"]
    for col in unknown_recode_cols:
        df[col] = df[col].replace("?", "Unknown")
        df[col] = df[col].fillna("Unknown")

    # 4. Numeric columns: cast back to correct types
    int_cols = [
        "encounter_id", "patient_nbr", "admission_type_id", "discharge_disposition_id", "admission_source_id", 
        "time_in_hospital", "num_lab_procedures", "num_procedures", "num_medications", "number_outpatient",
        "number_emergency", "number_inpatient", "number_diagnoses"
    ]
    for col in int_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce").astype("Int64")

    print(f"Shape after cleaning: {df.shape}")

    # PATIENTS table
    patients = (
        df.groupby("patient_nbr")
        .agg(
            race=("race", resolve_mode_first),
            gender=("gender", resolve_mode_first),
        )
        .reset_index()
    )
    print(f"patients: {patients.shape[0]} rows")

    # ENCOUNTERS table
    encounters = df[[
        "encounter_id", "patient_nbr", "admission_type_id", "discharge_disposition_id", "admission_source_id",
        "age", "medical_specialty", "payer_code", "time_in_hospital", "num_lab_procedures", "num_procedures",
        "num_medications", "number_outpatient", "number_emergency", "number_inpatient", "number_diagnoses", 
        "max_glu_serum", "A1Cresult", "change", "diabetesMed", "readmitted"
    ]].copy()

    encounters = encounters.rename(columns={
        "age": "age_group",
        "change": "change_flag",
        "diabetesMed": "diabetes_med",
    })
    print(f"encounters: {encounters.shape[0]} rows")

    # DIAGNOSES table (long format, positions 1-3)
    diag_frames = []
    for pos, col in [(1, "diag_1"), (2, "diag_2"), (3, "diag_3")]:
        sub = df[["encounter_id", col]].copy()
        sub = sub.rename(columns={col: "icd9_code"})
        sub["diagnosis_position"] = pos
        diag_frames.append(sub)

    diagnoses = pd.concat(diag_frames, ignore_index=True)
    # Drop rows with no diagnosis recorded at all for that position
    diagnoses = diagnoses[diagnoses["icd9_code"].notna()]
    diagnoses["diagnosis_category"] = diagnoses["icd9_code"].apply(map_icd9_category)
    diagnoses = diagnoses[["encounter_id", "diagnosis_position", "icd9_code", "diagnosis_category"]]
    diagnoses = diagnoses.sort_values(["encounter_id", "diagnosis_position"]).reset_index(drop=True)
    print(f"diagnoses: {diagnoses.shape[0]} rows")

    # MEDICATIONS table (long format, only status != 'No')
    med_cols = [
        "metformin", "repaglinide", "nateglinide", "chlorpropamide", "glimepiride",
        "acetohexamide", "glipizide", "glyburide", "tolbutamide", "pioglitazone",
        "rosiglitazone", "acarbose", "miglitol", "troglitazone", "tolazamide", "insulin",
        "glyburide-metformin", "glipizide-metformin", "glimepiride-pioglitazone",
        "metformin-rosiglitazone", "metformin-pioglitazone"
    ]

    med_frames = []
    for col in med_cols:
        sub = df[["encounter_id", col]].copy()
        sub = sub.rename(columns={col: "status"})
        sub["drug_name"] = col
        med_frames.append(sub)

    medications = pd.concat(med_frames, ignore_index=True)
    medications = medications[medications["status"] != "No"]
    medications = medications[["encounter_id", "drug_name", "status"]]
    medications = medications.sort_values(["encounter_id", "drug_name"]).reset_index(drop=True)
    print(f"medications: {medications.shape[0]} rows (status != 'No' only)")

    # outputs
    import os
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    patients.to_csv(f"{OUTPUT_DIR}/patients.csv", index=False)
    encounters.to_csv(f"{OUTPUT_DIR}/encounters.csv", index=False)
    diagnoses.to_csv(f"{OUTPUT_DIR}/diagnoses.csv", index=False)
    medications.to_csv(f"{OUTPUT_DIR}/medications.csv", index=False)

    print("Clean CSVs written to:", OUTPUT_DIR)
    print(f" patients.csv           {patients.shape[0]:>8,} rows")
    print(f" encounters.csv         {encounters.shape[0]:>8,} rows")
    print(f" diagnoses.csv          {diagnoses.shape[0]:>8,} rows")
    print(f" medications.csv        {medications.shape[0]:>8,} rows")

if __name__ == "__main__":
    main()