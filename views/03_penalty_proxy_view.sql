-- Hospital Readmission Reporting & Utilization Analysis
-- vw_diagnosis_category_penalty_proxy

-- Persists the HRRP-style penalty proxy logic from reporting/05_hrrp_penalty_proxy.sql, so PowerBI can pull it directly rather than reimplementing the ratio

-- Reminder: this is a proxy built from this dataset's own internal baseline 

USE hospital_readmission;

CREATE OR REPLACE VIEW vw_diagnosis_category_penalty_proxy AS WITH overall_rate AS (
    SELECT AVG(readmitted_30d) AS overall_readmission_rate
    FROM vw_encounter_full
),
category_rate AS (
    SELECT
        primary_diagnosis_category,
        COUNT(*)            AS total_encounters,
        AVG(readmitted_30d) AS category_readmission_rate
    FROM vw_encounter_full
    GROUP BY primary_diagnosis_category
)
SELECT
    cr.primary_diagnosis_category,
    cr.total_encounters,
    ROUND(cr.category_readmission_rate * 100, 2)                AS category_readmission_rate_pct,
    ROUND(o.overall_readmission_rate * 100, 2)                  AS overall_readmission_rate_pct,
    ROUND(cr.category_readmission_rate / o.overall_readmission_rate, 3) AS penalty_risk_proxy_ratio,
    CASE 
        WHEN cr.category_readmission_rate / o.overall_readmission_rate >= 1.0 THEN 'Above average -- monitor'
        ELSE 'Below average'
    END AS penalty_risk_flag
FROM category_rate cr
CROSS JOIN overall_rate o;