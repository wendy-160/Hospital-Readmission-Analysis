-- Hospital Readmission Reporting & Utilization Analysis 
-- 01 Descriptive / Operational Reports

-- Basic readmission-rate breakdowns by common reporting dimensions. 
-- All queries run against vw_encounter_full, which already excludes terminal (death/hospice) discharges and provides readmitted_30d as a clean binary flag.

USE hospital_readmission;

-- Overall 30-day readmission rate (headline metric)
SELECT
    COUNT(*)            AS total_encounters,
    SUM(readmitted_30d) As readmitted_within_30d,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full;

-- Readmission rate by age group
SELECT
    age_group,
    age_sort_order,
    COUNT(*)                AS total_encounters,
    SUM(readmitted_30d)     AS readmitted_within_30d,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full
GROUP BY age_group, age_sort_order
ORDER BY age_sort_order;

-- Readmission rate by admission type
SELECT 
    admission_type_desc,
    COUNT(*)                AS total_encounters,
    SUM(readmitted_30d)     AS readmitted_within_30d,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full
GROUP BY admission_type_desc
ORDER BY readmission_rate_pct DESC;

-- Readmission rate by medical specialty (top 15 by volume)
-- Specialty here reflects the admitting physician's specialty, not a full provider entity
SELECT 
    medical_specialty,
    COUNT(*)            AS total_encounters,
    SUM(readmitted_30d) AS readmitted_within_30d,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full
GROUP BY medical_specialty
ORDER BY total_encounters DESC
LIMIT 15;

-- Readmission rate by payer code
SELECT
    payer_code,
    COUNT(*)            AS total_encounters,
    SUM(readmitted_30d) AS readmitted_within_30d,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full
GROUP BY payer_code
ORDER BY total_encounters DESC;

-- Readmission rate by primary diagnosis category
SELECT
    primary_diagnosis_category,
    COUNT(*)                AS total_encounters,
    SUM(readmitted_30d)     AS readmitted_within_30d,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full
GROUP BY primary_diagnosis_category
ORDER BY readmission_rate_pct DESC;

-- Readmission rate by discharge disposition (top 10 by volume)
SELECT 
    discharge_disposition_desc,
    COUNT(*)                AS total_encounters,
    SUM(readmitted_30d)     AS readmitted_within_30d,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full
GROUP BY discharge_disposition_desc
ORDER BY total_encounters DESC
LIMIT 10;

-- Readmission rate by whether any medication was increased (quick look at whether inpatient med intensification tracks with readmission)
SELECT 
    any_medication_increased,
    COUNT(*)                AS  total_encounters,
    SUM(readmitted_30d)     AS readmitted_within_30d,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM vw_encounter_full
GROUP BY any_medication_increased;