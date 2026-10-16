"""
Stage 2 - Load into MySQL
Hospital Readmission Reporting & Utilizaiton Analysis

Reads the CSVs produced by 01_transform.py in ../data/processed/ and loads them into the MySQL scehma defined in /schema/01_schema.sql.
Loads in foreign-key order: patients -> encounters -> diagnoses -> medications
"""

import pandas as pd
import mysql.connector
from mysql.connector import Error
import os

DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": os.environ["MYSQL_PASSWORD"],
    "database": "hospital_readmission",
}

INPUT_DIR = "../data/processed"
BATCH_SIZE = 5000

def load_table(cursor, conn, csv_path, insert_sql, columns, label):
    df = pd.read_csv(csv_path, dtype=str, keep_default_na=False, na_values=[])

    # Convert empty strings back to None so MySQL stores true NULLs 
    df = df.where(df != "", None)

    rows = df[columns].values.tolist()

    total = len(rows)
    for i in range(0, total, BATCH_SIZE):
        batch = rows[i:i + BATCH_SIZE]
        cursor.executemany(insert_sql, batch)
        conn.commit()
        print(f"    {min(i + BATCH_SIZE, total):>8,} / {total:,} rows committed")
    print(f"{label}: {total:,} rows loaded.\n")

def main():
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print(f"Successfully connected to MySQL.\n")

        # 1. patients
        load_table(
            cursor, conn,
            f"{INPUT_DIR}/patients.csv",
            "INSERT INTO patients (patient_nbr, race, gender) VALUES (%s, %s, %s)",
            ["patient_nbr", "race", "gender"],
            "patients"
        )

        # 2. encounters
        encounter_cols = [
            "encounter_id", "patient_nbr", "admission_type_id", "discharge_disposition_id", "admission_source_id",
            "age_group", "medical_specialty", "payer_code", "time_in_hospital", "num_lab_procedures", "num_procedures", 
            "num_medications", "number_outpatient", "number_emergency", "number_inpatient", "number_diagnoses",
            "max_glu_serum", "A1Cresult", "change_flag", "diabetes_med", "readmitted"
        ]
        placeholders = ", ".join(["%s"] * len(encounter_cols))
        load_table(
            cursor, conn,
            f"{INPUT_DIR}/encounters.csv",
            f"INSERT INTO encounters ({', '.join(encounter_cols)}) VALUES ({placeholders})",
            encounter_cols,
            "encounters"
        )

        # 3. diagnoses
        load_table(
            cursor, conn,
            f"{INPUT_DIR}/diagnoses.csv",
            "INSERT INTO diagnoses (encounter_id, diagnosis_position, icd9_code, diagnosis_category) "
            "VALUES (%s, %s, %s, %s)",
            ["encounter_id", "diagnosis_position", "icd9_code", "diagnosis_category"],
            "diagnoses"
        )

        # 4, medications
        load_table(
            cursor, conn,
            f"{INPUT_DIR}/medications.csv",
            "INSERT INTO medications (encounter_id, drug_name, status) VALUES (%s, %s, %s)",
            ["encounter_id", "drug_name", "status"],
            "medications"
        )

    except Error as e:
        print(f"MySQL error: {e}")
        if conn.is_connected():
            conn.rollback()
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals() and conn.is_connected():
            conn.close()
            print("Connection closed.")

if __name__ == "__main__":
    main()