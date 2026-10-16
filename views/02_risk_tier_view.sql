-- Hospital Readmission Reporting & Utilization Analysis
-- vw_encounter_risk_tier

-- Persists the rule-based risk scoring logic from reporting/04_risk_segmentation.sql as a view
-- (this is so Power BI can pull risk_tier directly without re-implementing the CASE logic. keeps scoring rule defined in exactly one place)

USE hospital_readmission;

CREATE OR REPLACE VIEW vw_encounter_risk_tier AS 
SELECT 
    e.encounter_id, 
    e.patient_nbr,
    e.primary_diagnosis_category,
    e.discharge_disposition_desc,
    e.readmitted_30d,
    (e.number_outpatient + e.number_emergency + e.number_inpatient) AS prior_year_visits,

    CASE
        WHEN (e.number_outpatient + e.number_emergency + e.number_inpatient) >= 3 THEN 2
        WHEN (e.number_outpatient + e.number_emergency + e.number_inpatient) BETWEEN 1 AND 2 THEN 1
        ELSE 0
    END
    +
    CASE
        WHEN e.primary_diagnosis_category IN ('Diabetes', 'Injury', 'Circulatory') THEN 1
        ELSE 0
    END 
    +
    CASE
        WHEN e.discharge_disposition_desc != 'Discharged to home' THEN 1
        ELSE 0
    END                                                     AS risk_score,

    CASE
        WHEN 
            (CASE
                WHEN (e.number_outpatient + e.number_emergency + e.number_inpatient) >= 3 THEN 2
                WHEN (e.number_outpatient + e.number_emergency + e.number_inpatient) BETWEEN 1 AND 2 THEN 1
                ELSE 0
            END
            +
            CASE 
                WHEN e.primary_diagnosis_category IN ('Diabetes', 'Injury', 'Circulatory') THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN e.discharge_disposition_desc != 'Discharged to home' THEN 1
                ELSE 0 
            END) >= 3 THEN 'High'
        WHEN 
            (CASE
                WHEN (e.number_outpatient + e.number_emergency + e.number_inpatient) >= 3 THEN 2
                WHEN (e.number_outpatient + e.number_emergency + e.number_inpatient) BETWEEN 1 AND 2 THEN 1
                ELSE 0
            END 
            +
            CASE
                WHEN e.primary_diagnosis_category IN ('Diabetes', 'Injury', 'Circulatory') THEN 1
                ELSE 0
            END
            + 
            CASE
                WHEN e.discharge_disposition_desc != 'Discharged to home' THEN 1
                ELSE 0
            END) = 2 THEN 'Medium'
        ELSE 'Low'
    END                                             AS risk_tier


FROM vw_encounter_full e;