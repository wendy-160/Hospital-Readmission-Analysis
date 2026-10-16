-- Hospital Readmission Reporting & Utilization Analysis
-- 05 HRRP Style Penalty Risk Proxy

-- CMS's Hospital Readmission Reduction Program (HRRP) penalizes hospitals based on 30-day readmission rates for specific conditions, benchmarked against a national/peer expected rate 
-- (the "Excess Readmission Ratio" = observed / expected).

-- This query builds a PROXY metric only.
-- Each primary diagnosis category's observed 30-day readmision rate relative to this dataset's own overall rate.
-- A ratio above 1.0 means that category is readmitting at an above-average rate relative to the whole population (its the kind of category a real HRRP calculation would be watching closely)
-- This is NOT a real HRRP Excess Readmission Ratio and should not be represented as one

USE hospital_readmission;

WITH overall_rate AS (
    SELECT AVG(readmitted_30d) AS overall_readmission_rate
    FROM vw_encounter_full
),
category_rate AS (
    SELECT 
        primary_diagnosis_category,
        COUNT(*)                AS total_encounters,
        AVG(readmitted_30d)     AS category_readmission_rate
    FROM vw_encounter_full
    GROUP BY primary_diagnosis_category
)
SELECT
    cr.primary_diagnosis_category,
    cr.total_encounters,
    ROUND(cr.category_readmission_rate * 100, 2)        AS category_readmission_rate_pct,
    ROUND(o.overall_readmission_rate * 100, 2)          AS overall_readmission_rate_pct,
    ROUND(cr.category_readmission_rate / o.overall_readmission_rate, 3) AS penalty_risk_proxy_ratio,
    CASE 
        WHEN cr.category_readmission_rate / o.overall_readmission_rate >= 1.0 THEN 'Above average -- monitor'
        ELSE 'Below average'
    END AS penalty_risk_flag
FROM category_rate cr
CROSS JOIN overall_rate o
ORDER BY penalty_risk_proxy_ratio DESC;