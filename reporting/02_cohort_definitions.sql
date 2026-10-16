-- Hospital Readmission Reporting & Utilization Analysis 
-- 02 Cohort Definitions

-- Defines reusable patient/encounter cohorts using CTEs, then reports one each. 
-- These represent the kind of segment definitions a hospital quality/care-management team would build to target outreach or monitoring

USE hospital_readmission;

-- Cohort 1: Repeat-encounter patients
-- Patients with 2+ reportable encounters in the dataset
-- a proxy for chronic/high-utilization patients worth flagging for care coordination
WITH encounter_counts AS (
    SELECT
        patient_nbr,
        COUNT(*) AS num_encounters
    FROM vw_encounter_full
    GROUP BY patient_nbr
)
SELECT
    CASE
        WHEN num_encounters = 1 THEN '1 (single encounter)'
        WHEN num_encounters BETWEEN 2 AND 3 THEN '2-3'
        WHEN num_encounters BETWEEN 4 AND 6 THEN '4-6'
        ELSE '7+'
    END AS encounter_count_bucket,
    COUNT(*) AS num_patients
FROM encounter_counts
GROUP BY encounter_count_bucket
ORDER BY MIN(num_encounters);

-- Cohort 2: Repeat-encounter patients' readmission rate
-- Do patients with multiple encounters have a different readmission profile than single-encounter patients?
WITH encounter_counts AS (
    SELECT
        patient_nbr,
        COUNT(*) AS num_encounters
    FROM vw_encounter_full
    GROUP BY patient_nbr
),
tagged_encounters AS (
    SELECT
        e.*, 
        CASE WHEN ec.num_encounters > 1 THEN 'Repeat patient' ELSE 'Single encounters' END AS patient_type
        FROM vw_encounter_full e 
        JOIN encounter_counts ec ON e.patient_nbr = ec.patient_nbr
)
SELECT
    patient_type,
    COUNT(*)            AS total_encounters,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM tagged_encounters
GROUP BY patient_type;

-- Cohort 3: Encounters with an insulin dosage change
-- Patients whose insulin was actively adjusted (Up or Down) during the encounter
-- a marker of active glycemic management
WITH insulin_changes AS (
    SELECT DISTINCT encounter_id
    FROM medications
    WHERE drug_name = 'insulin' AND status IN ('Up', 'Down')

)
SELECT 
    CASE WHEN ic.encounter_id IS NOT NULL THEN 'Insulin adjusted' ELSE 'No insulin adjustment' END AS insulin_status,
    COUNT(*)        AS total_encounters,
    ROUND(AVG(e.readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full e 
LEFT JOIN insulin_changes ic ON e.encounter_id = ic.encounter_id
GROUP BY insulin_status;

-- Cohort 4: High prior-utilization patients
-- Flags encounters where the patient had a significant utilization in the year preceding this encounter (outpatient + emergency + inpatient visits combined)
-- a standard risk signal in readmission literature 
WITH utilization_tagged AS (
    SELECT
        e.*,
        (e.number_outpatient + e.number_emergency + e.number_inpatient) AS prior_year_visits
    FROM vw_encounter_full e 
)
SELECT 
    CASE 
        WHEN prior_year_visits = 0 THEN '0 prior visits'
        WHEN prior_year_visits BETWEEN 1 AND 2 THEN '1-2 prior visits'
        WHEN prior_year_visits BETWEEN 3 AND 5 THEN '3-5 prior visits'
        ELSE '6+ prior visits'
    END AS prior_utilization_bucket,
    COUNT(*)                            AS total_encounters,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM utilization_tagged
GROUP BY prior_utilization_bucket
ORDER BY MIN(prior_year_visits);