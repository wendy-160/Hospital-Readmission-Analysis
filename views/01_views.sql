-- Hospital Readmission Reporting & Utilization Analysis
-- Views Layer

-- Run after schema/01_schema.sql, schema/02_lookup_data.sql, and the full ETL load 
-- (etl/01_transform.py -> etl/02_load_mysql.py).

USE hospital_readmission;

-- vw_reportable_encounters
-- All encounters EXCLUDING terminal discharges (death or hospice).
-- This is the base view for any readmission-rate calculation. 
-- Patients who died or entered hospice were never eligible for readmission, so including them would understate true rates.
-- Raw `encounters` table is left untouched for volume/utilization reporting where these encounters should still count.
CREATE OR REPLACE VIEW vw_reportable_encounters AS 
SELECT e.*
FROM encounters e
JOIN discharge_disposition_lookup dd 
    ON e.discharge_disposition_id = dd.discharge_disposition_id
WHERE dd.is_terminal_discharge = FALSE;

-- vw_primary_diagnosis
-- Isolates just the primary (position 1) diagnosis per encounter, since diagnoses is stored long-format (up to 3 rows/encounter) and most reporting cares about the primary diagnosis only. 
CREATE OR REPLACE VIEW vw_primary_diagnosis AS 
SELECT encounter_id, icd9_code, diagnosis_category
FROM diagnoses
WHERE diagnosis_position = 1;

-- vw_medication_summary
-- One row per encounter, sumarizing medication activity.
-- medications only contains rows where status != 'No', so an encounter absent from this view had no active diabetic medications recorded
CREATE OR REPLACE VIEW vw_medication_summary AS 
SELECT 
    encounter_id,
    COUNT(*)                                            AS num_active_medications,
    SUM(CASE WHEN status = 'Up'     THEN 1 ELSE 0 END) AS num_increased,
    SUM(CASE WHEN status = 'Down'   THEN 1 ELSE 0 END) AS num_decreased,
    SUM(CASE WHEN status = 'Steady' THEN 1 ELSE 0 END) AS num_steady,
    SUM(CASE WHEN status = 'Up'     THEN 1 ELSE 0 END) AS any_medication_increased,
    SUM(CASE WHEN status = 'Down'   THEN 1 ELSE 0 END) AS any_medication_decreased
FROM medications
GROUP BY encounter_id;

-- vw_encounter_full
-- The main reporting view: one row per REPORTABLE encounter (terminal discharges excluded), with all dimension lookups joined and readmission flags derived. 
-- This is the primary source for SQL reporting queries and the Power BI dashboard.
CREATE OR REPLACE VIEW vw_encounter_full AS 
SELECT
    e.encounter_id,
    e.patient_nbr,
    p.race,
    p.gender,
    e.age_group,
    al.sort_order               AS age_sort_order,
    e.admission_type_id,
    at_lk.description           AS admission_type_desc,
    e.discharge_disposition_id,
    dd.description              AS discharge_disposition_desc,
    e.admission_source_id,
    asrc.description            AS admission_source_desc,
    e.medical_specialty,
    e.payer_code,
    e.time_in_hospital,
    e.num_lab_procedures,
    e.num_procedures,
    e.num_medications,
    e.number_outpatient,
    e.number_emergency,
    e.number_inpatient,
    e.number_diagnoses,
    e.max_glu_serum,
    e.A1Cresult,
    e.change_flag,
    e.diabetes_med,
    e.readmitted,
    CASE WHEN e.readmitted = '<30' THEN 1 ELSE 0 END                AS readmitted_30d,
    CASE WHEN e.readmitted IN ('<30', '>30') THEN 1 ELSE 0 END      AS readmitted_any,
    pd.diagnosis_category               AS primary_diagnosis_category,
    pd.icd9_code                        AS primary_icd9_code,
    COALESCE(ms.num_active_medications, 0) AS num_active_medications,
    COALESCE(ms.any_medication_increased, 0) AS any_medication_increased,
    COALESCE(ms.any_medication_decreased, 0) AS any_medication_decreased
FROM encounters e
JOIN patients p
    ON e.patient_nbr = p.patient_nbr
JOIN discharge_disposition_lookup dd
    ON e.discharge_disposition_id = dd.discharge_disposition_id
LEFT JOIN admission_type_lookup at_lk
    ON e.admission_type_id = at_lk.admission_type_id
LEFT JOIN admission_source_lookup asrc
    ON e.admission_source_id = asrc.admission_source_id
LEFT JOIN age_lookup al
    ON e.age_group = al.age_group
LEFT JOIN vw_primary_diagnosis pd
    ON e.encounter_id = pd.encounter_id
LEFT JOIN vw_medication_summary ms
    ON e.encounter_id = ms.encounter_id
WHERE dd.is_terminal_discharge = FALSE;