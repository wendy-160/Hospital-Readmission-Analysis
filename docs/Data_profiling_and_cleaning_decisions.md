# Data Profiling & Cleaning Decisions

**Project:** Hospital Readmission Reporting & Utilization Analysis Using SQL and Clinical Encounter Data

**Source Data:** Diabetes 130-US Hospitals dataset (1999-2008), Strack et al., _Biomed Research International_, 2014

**Raw File:** `diabetic_data.csv` - 101,766 rows x 50 columns

This document records the data quality issues identified during the profiling and the decisions made in response, with rationale. This step was before the schema design as the schema was built to fit what the data actually contains and not the other way around.

---

## 1. Base Integrity Checks

| Check                               | Result  |
| ----------------------------------- | ------- |
| Duplicate `encounter_id` values     | 0       |
| Fully duplicate rows                | 0       |
| Total Encounters                    | 101,766 |
| Unique patients (`patient_nbr`)     | 71,518  |
| Patients with 2+ encounters         | 16,773  |
| Max encounters for a single patient | 40      |

**Decision:** The normalized schema design requires putting patients and encounters in two different tables because the data contains 16,773 patients with multiple encounters. This justifies that patients and encounters are two different entities that should be placed in separate tables.

---

## 2. Missing/Placeholder Values (`?` recoded as null)

| Column              | % Missing | Decision                     | Rationale                                                                                                                                                                                                         |
| ------------------- | --------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `weight`            | 96.8%     | Drop Column                  | Almost entirely missing and therefore not usable for reporting. (Consistent with source paper's own finding. Hospitals weren't required to capture weight in structured format prior to 2009 HITECH legislation.) |
| `medical_specialty` | 49.08%    | Keep and recode to `Unknown` | Too much signal to discard and the missingness itself could correlate to admission type                                                                                                                           |
| `payer_code`        | 39.56%    | Keep and recode to `Unknown` | Like with `medical_specialty`, it could be relevant to "utilization/reporting" framing even if not used in every query                                                                                            |
| `race`              | 2.3%      | Keep; recode to `Unknown`    | Low missingness, easy to retain.                                                                                                                                                                                  |
| `diag_3`            | 1.40%     | Keep; recode to `Unknown`    |                                                                                                                                                                                                                   |
| `diag_2`            | 0.35%     | Keep; recode to `Unknown`    |                                                                                                                                                                                                                   |
| `diag_3`            | 0.02%     | Keep; recode to `Unknown`    | Negligible.                                                                                                                                                                                                       |

---

## 3. Zero-Variance Columns

| Column        | Finding                                            | Decision        |
| ------------- | -------------------------------------------------- | --------------- |
| `examide`     | Only value present: `"No"` across all 101,766 rows | **Drop column** |
| `citoglipton` | Only value present: `"No"` across all 101,766 rows | **Drop Column** |

**Rationale:** Zero variance means no analytical value so carrying them into the schema adds noise with no informational benefit.

## 4. Invalid / Low-Value Rows

| Issue                        | Finding | Decision              |
| ---------------------------- | ------- | --------------------- |
| `gender = "Unknown/Invalid"` | 3 rows  | **Drop these 3 rows** |

**Rationale:** Immaterial to result size (0.003% of data)

## 5. Discharge Diposition - Expired / Hospice Encounters

Using the official `IDS_mapping.csv` (UCI) code descriptions:
| Category | `discharge_disposition_id` codes | Count |
| --- | --- | --- |
| Death (Expired) | 11, 19, 20, 21 | 1,652 |
| Hospice | 13, 14 | 771 |
| Combined (death + hospice) | 11, 13, 14, 19, 20, 21 | **2,423 (2.38%)** |

All 2,423 of these encounters show `readmitted = "NO"` which, although technically true, is also misleading since the patients were never eligible for readmission in the first place. They either died or entered hospice.

**Decision:** These rows will **not** be deleted but instead flagged via a `discharge_disposition_lookup` attribute (e.g., `is_terminal_discharge`). They will also be **excluded at the view layer** when calculating readmission rates.

**Rationale:** Doing so preserves raw data integrity (useful for utilization/volume reporting where these encounters still count) while preventing them from distorting readmission-rate metrics.

---

## 6. Delibereate Deviation from Source Paper Methodology

The original study reduced its analytical dataset to 69,984 encounters using two filters:

1. Exclude expired/hospice discharges (1,652 encounters). (replicated via view-layer filtering)
2. Retain only the _first_ encounter per patient, to satisfy the independence assumption required for their logistic regression model. (not replicated in this project)

**Rationale:** The one-encounter-per-patient restriction exists to satisfy a statistical modeling assumption, which isn't a constraint for SQL-based operational reporting. A hospital utilization/quality reporting pipeline should reflect all qualifying encounters, not just first ones. This project is not fitting a regression model, so there is no equivalent restriction to satisfy. All 101,766 encounters (minus the view-layer exclusions noted above) are retained.

---

## 7. Diagnosis Code Grouping

`diag_1`, `diag_2`, `diag_3` contain raw ICD-9 codes (numeric codes plus V/E supplemental classification codes), with high cardinality (hundreds of distinct codes per field).

**Decision:** Map raw codes into clinical categories using the published grouping scheme from Strack et al. (2014, Table 2): Circulatory, Respiratory, Digestive, Diabetes, Injury, Musculoskeletal, Genitourinary, Neoplasms, and Other (covering lower-frequency categories such as infectious/parasitic, mental disorders, skin conditions, etc.). See `icd9_category_mapping.md` for the full reference table.

---

## 8. Medication Columns - Unpivoting

23 medicaiton columns (metformin, insulin, glipizide, etc., plus combination drugs) recorded per encounter as `No` / `Steady` / `Up` / `Down`. Two of these (`examide`, `citoglipton`) were dropped for zero variance (#3), leaving about 21 medication columns with genuine variance.

**Decision:** Unpivot from wide format into a long-format `medications` table (`encounter_id`, `drug_name`, `status`), rather than retaining 21 seperate columns on the encounters table. Only rows where `status != 'No'` are inserted (i.e., the table records actualy prescribing events (Steady/Up/Down)).

**Rationale:** Wide medication columns don't normalize well and make SQL querying across drugs awkward (e.g., "How many patients have had any medication increased" requires checking 21 columns individually in wide format vs. a simple `WHERE status = 'Up'` in long format). Inserting `status = 'No'` rows for all ~21 drugs x 101,766 encounters would produce roughly 2M+ rows that are almost entirely non-informative placeholders, bloating the table without adding analytical value.

---

## 9. Target Variable Distribution

| `readmitted` value | Count  | %      |
| ------------------ | ------ | ------ |
| `NO`               | 54,864 | 53.91% |
| `>30`              | 35,545 | 34.93% |
| `<30`              | 11,357 | 11.16% |

**Decision:** Retain the raw 3-category field in `encounters`. Binary readmission flags (e.g., "readmitted within 30 days: Y/N") will be derived at the **view layer**, not stored redundantly in the base table.

---

## 10. Key Categorical Field Cardinality (for lookup table sizing)

| Field                      | Distinct Values               |
| -------------------------- | ----------------------------- |
| `race`                     | 6                             |
| `gender`                   | 3 (2 after cleaning)          |
| `age`                      | 10 (pre-binned decade ranges) |
| `admission_type_id`        | 8                             |
| `discharge_disposition_id` | 26                            |
| `admission_source_id`      | 17                            |
| `medical_specialty`        | 73                            |
| `payer_code`               | 18                            |

---

## 11. `age_group` Placement (Encounters,not Patients)

Initial schema design placed `age_group` on `patients`, treating it as a fixed demographic trait. Profiling showed this assumption doesn't hold:

| Check                                                                    | Result        |
| ------------------------------------------------------------------------ | ------------- |
| Patients with more than one distinct `age` value across their encounters | 1,574         |
| Of those, patients whose age increases over time                         | 1,556 (98.9%) |
| Patients with non-monotonic age changes (likely data noise)              | 18 (1.1%)     |

Since the dataset spans 1999-2008, patients with multiple encounters can age from one decade band into the next between visits (e.g., `[50-60)` -> `[60-70)`). This confirms `age_group` is a fact about a specific encounter in time, not a stable attribute of the patient.

**Decision:** Move `age_group` from `patients` to `encounters`. `patients` retains only `patient_nbr`, `race`, and `gender`.

**Rationale:** Keeping age on `patients` would force and arbitrary single value per patient (e.g., "first encounter's age"), discarding real information relevant to reporting such as readmision rate by age at the time of that admission.

## 12. ETL / MySQL Load Troubleshooting

Two issues surfaced during the actual load into MySQL (via `etl/02_load_mysql.py`) that did not show up furing the verification at the CSV file level, as they are subject to column constraints and rely on a database with history.

**Issue 1:** Column width too narrow for legitimate lookup values (`Error 1406: Data too long for column`)
Two lookup columns were originally sized `VARCHAR(100)`, based on a estimate rather than checking actual string lengths against the official `IDS_mapping.csv` values:

- `discharge_disposition_lookup.description`: code 24 and code 28 descriptions are 103 and 105 characters
- `diagnosis_category_lookup.icd9_range_description`: the "Other" category's description is 116 characters

MySQL stops on the first error by default so the script appeared to run but silently left the lookup table partially populated (`discharge_disposition_lookup` stopped after code 15 the first time and again after code 23). There was no obvious indication anything was wrong until downstream foreign key insert failed much later.

**Decision:** Widen both columns to `VARCHAR(150)` in `01_schema.sql`. Applied via `ALTER TABLE __ MODIFY ___`on the already created tables.

When sizing lookup columns from an external source, like `IDS_mapping.csv`, check the actual max string length in the source data rather then guessinf a round number.

**Issue 2:** Batch-commit load script has no rerun safety net
`02_load_mysql.py` commits every 5,000 rows as it loads. When a load run fails partway through, the rows already committed remain in the database. Re-running the script after fixing the root cause immediately fails with a duplicate primary key errror (`Error 1062: Duplicate entry ... for key 'patients.PRIMARY'`), since `patients` had alreadt fully loaded successfully in the earlier attempt.

**Decision:** Before any rerun, manually truncate the data tables (not the lookup tables, which don't need to change) in FK-safe order:

```sql
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE medications;
TRUNCATE TABLE diagnoses;
TRUNCATE TABLE encounters;
TRUNCATE TABLE patients;
SET FOREIGN_KEY_CHECKS=1;
```

## Summary of Structural Decisions Feeding Into Schema Design

- Drop: `weight`, `examide`, `citoglipton`
- Drop: 3 rows from gender
- Recode `?` -> `Unknown`: `race`, `medical_specialty`, `payer_code`, `diag_1/2/3`
- Normalize: `patients` and `encounters` as separate tables (justified by repeat-encounter structure)
- `age_group` modeled on `encounters`, not `patients`
- Long format: `diagnosis` (diag position 1-3) and `medications` (21 drugs) instead of wide columns
- View-layer exclusion (not row deletion): expired/dospice discharges for readmission-rate metrics
- No `providers` table: `medical_specialty` retained as a field on `encounters`, since the dataset provides specialty of admitting physician only. (not a true provider identifier)
- No one-encounter-per-patient restriction: full encounter-level reporting retained (deviation from source paper, documented and justified above)
