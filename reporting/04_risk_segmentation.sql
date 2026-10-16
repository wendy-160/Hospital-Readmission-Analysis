-- Hospital Readmission Reporting & Utilization Analysis
-- 04 Risk Segmentation (rule-based, not predictive modeling)

-- Builds a transparent, rule-based risk tier per encounter using CASE logic on factors already established as associated with readmission in the descriptive reports

USE hospital_readmission;

WITH scored_encounters AS (
    SELECT 
        e.encounter_id,
        e.patient_nbr,
        e.primary_diagnosis_category,
        e.discharge_disposition_desc,
        (e.number_outpatient + e.number_emergency + e.number_inpatient) AS prior_year_visits,
        e.readmitted_30d,

        -- point 1: prior-year utilization
        CASE
            WHEN (e.number_outpatient + e.number_emergency + e.number_inpatient) >= 3 THEN 2
            WHEN (e.number_outpatient + e.number_emergency + e.number_inpatient) BETWEEN 1 AND 2 THEN 1
            ELSE 0
        END AS utilization_points,

        -- point 2: higher-risk primary diagnosis category
        -- (Diabetes, Injury, Circulatory identified as the three highest-readmssion-rate categories in 01_decriptive_reports.sql)
        CASE
            WHEN e.primary_diagnosis_category IN ('Diabetes', 'Injury', 'Circulatory') THEN 1 
            ELSE 0
        END AS diagnosis_risk_points,

        -- point 3: discharge somewhere other than home
        -- transfers/facility discharges carry more care-transition risk than a routine discharge home
        CASE
            WHEN e.discharge_disposition_desc != 'Discharged to home' THEN 1 
            ELSE 0
        END AS discharge_risk_points
    
    FROM vw_encounter_full e
),
tiered_encounters AS (
    SELECT
        *,
        (utilization_points + diagnosis_risk_points + discharge_risk_points) AS risk_score,
        CASE 
            WHEN (utilization_points + diagnosis_risk_points + discharge_risk_points) >= 3 THEN 'High'
            WHEN (utilization_points + diagnosis_risk_points + discharge_risk_points) = 2 THEN 'Medium'
            ELSE 'Low'
        END AS risk_tier
    FROM scored_encounters
)
SELECT
    risk_tier,
    COUNT(*)                AS total_encounters,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_all_encounters,
    ROUND(AVG(readmitted_30d) * 100, 2) AS readmission_rate_pct
FROM tiered_encounters
GROUP BY risk_tier
ORDER BY FIELD(risk_tier, 'Low', 'Medium', 'High');
