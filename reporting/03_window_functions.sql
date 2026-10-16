-- Hospital Readmission Reporting & Utilization Analysis 
-- 03 Window Functions

-- This dataset does not contain a specific date or timestamp for admission. 
-- It only shares the assigned encunter_id number which is used as a substitute for choronological order within a patient.

USE hospital_readmission;

-- Encounter sequence number per patient
-- Numbers each patient's encounters in order (1st, 2nd, 3rd...), useful for distinguishing a patient's first admission form their later ones in downstream queries.
SELECT 
    encounter_id,
    patient_nbr, 
    ROW_NUMBER() OVER (PARTITION BY patient_nbr ORDER BY encounter_id) AS encounter_sequence,
    readmitted_30d
FROM vw_encounter_full
ORDER BY patient_nbr, encounter_sequence
LIMIT 50;

-- Running count of a patient's prior encounters in this dataset (i.e., how many times have we seen this patient before this encounter)
SELECT 
    encounter_id,
    patient_nbr,
    COUNT(*) OVER (
        PARTITION BY patient_nbr
        ORDER BY encounter_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS prior_encounters_in_dataset,
    readmitted_30d
FROM vw_encounter_full
ORDER BY patient_nbr, encounter_id
LIMIT 50;

-- Was the patient's immediately preceding encounter a readmission?
-- Uses LAG() to look at the previous row's readmitted_30d flag within each patient's encunter sequence
SELECT 
    encounter_id, 
    patient_nbr,
    readmitted_30d,
    LAG(readmitted_30d) OVER (PARTITION BY patient_nbr ORDER BY encounter_id) AS prior_encounter_was_readmission
FROM vw_encounter_full
ORDER BY patient_nbr, encounter_id
LIMIT 50;

-- Readmission rate ranked across diagnosis categories
-- RANK() over the aggregated rate lets a report show "diagnosis category readmission rank" alongside the raw rate
WITH category_rates AS (
    SELECT 
        primary_diagnosis_category,
        COUNT(*)                        AS total_encounters,
        ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
    FROM vw_encounter_full
    GROUP BY primary_diagnosis_category
)
SELECT
    primary_diagnosis_category,
    total_encounters,
    readmission_rate_pct,
    RANK() OVER (ORDER BY readmission_rate_pct DESC) AS readmission_rate_rank
FROM category_rates
ORDER BY readmission_rate_rank;

-- Time-in-hospital percentile bucketing
-- NTILE() splits encunters into quartiles by length of stay, useful for a "does length of stay track with readmission" view without hardcoding bucket boundaries.
WITH stay_quartiles AS (
    SELECT
        encounter_id,
        time_in_hospital,
        readmitted_30d,
        NTILE(4) OVER (ORDER BY time_in_hospital) AS stay_length_quartile
    FROM vw_encounter_full
)
SELECT
    stay_length_quartile, 
    MIN(time_in_hospital)       AS min_days,
    MAX(time_in_hospital)       AS max_days,
    COUNT(*)                    AS total_encounters,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM stay_quartiles
GROUP BY stay_length_quartile
ORDER BY stay_length_quartile;