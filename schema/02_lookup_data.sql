-- Lookup Table Population
-- Source: IDS_mapping.csv (UCI Diabetes 130-US Hospitals dataset)

USE hospital_readmission;

-- admission_type_lookup
INSERT INTO admission_type_lookup (admission_type_id, description) VALUES (1, 'Emergency');
INSERT INTO admission_type_lookup (admission_type_id, description) VALUES (2, 'Urgent');
INSERT INTO admission_type_lookup (admission_type_id, description) VALUES (3, 'Elective');
INSERT INTO admission_type_lookup (admission_type_id, description) VALUES (4, 'Newborn');
INSERT INTO admission_type_lookup (admission_type_id, description) VALUES (5, 'Not Available');
INSERT INTO admission_type_lookup (admission_type_id, description) VALUES (6, 'NULL');
INSERT INTO admission_type_lookup (admission_type_id, description) VALUES (7, 'Trauma Center');
INSERT INTO admission_type_lookup (admission_type_id, description) VALUES (8, 'Not Mapped');

-- discharge_disposition_lookup
-- is_terminal_discharge = TRUE for death (11, 19, 20, 21) and hospice (13, 14) codes
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (1, 'Discharged to home', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (2, 'Discharged/transferred to another short term hospital', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (3, 'Discharged/transferred to SNF', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (4, 'Discharged/transferred to ICF', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (5, 'Discharged/transferred to another type of inpatient care institution', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (6, 'Discharged/transferred to home with home health service', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (7, 'Left AMA', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (8, 'Discharged/transferred to home under care of Home IV provider', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (9, 'Admitted as an inpatient to this hospital', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (10, 'Neonate discharged to another hospital for neonatal aftercare', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (11, 'Expired', TRUE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (12, 'Still patient or expected to return for outpatient services', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (13, 'Hospice / home', TRUE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (14, 'Hospice / medical facility', TRUE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (15, 'Discharged/transferred within this institution to Medicare approved swing bed', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (16, 'Discharged/transferred/referred another institution for outpatient services', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (17, 'Discharged/transferred/referred to this institution for outpatient services', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (18, 'NULL', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (19, 'Expired at home. Medicaid only, hospice.', TRUE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (20, 'Expired in a medical facility. Medicaid only, hospice.', TRUE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (21, 'Expired, place unknown. Medicaid only, hospice.', TRUE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (22, 'Discharged/transferred to another rehab fac including rehab units of a hospital .', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (23, 'Discharged/transferred to a long term care hospital.', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (24, 'Discharged/transferred to a nursing facility certified under Medicaid but not certified under Medicare.', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (25, 'Not Mapped', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (26, 'Unknown/Invalid', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (30, 'Discharged/transferred to another Type of Health Care Institution not Defined Elsewhere', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (27, 'Discharged/transferred to a federal health care facility.alid', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (28, 'Discharged/transferred/referred to a psychiatric hospital of psychiatric distinct part unit of a hospital', FALSE);
INSERT INTO discharge_disposition_lookup (discharge_disposition_id, description, is_terminal_discharge) VALUES (29, 'Discharged/transferred to a Critical Access Hospital (CAH).', FALSE);

-- admission_source_lookup
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (1, 'Physician Referral');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (2, 'Clinic Referral');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (3, 'HMO Referral');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (4, 'Transfer from a hospital');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (5, 'Transfer from a Skilled Nursing Facility (SNF)');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (6, 'Transfer from another health care facility');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (7, 'Emergency Room');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (8, 'Court/Law Enforcement');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (9, 'Not Available');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (10, 'Transfer from critial access hospital');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (11, 'Normal Delivery');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (12, 'Premature Delivery');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (13, 'Sick Baby');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (14, 'Extramural Birth');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (15, 'Not Available');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (17, 'NULL');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (18, 'Transfer From Another Home Health Agency');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (19, 'Readmission to Same Home Health Agency');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (20, 'Not Mapped');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (21, 'Unknown/Invalid');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (22, 'Transfer from hospital inpt/same fac reslt in a sep claim');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (23, 'Born inside this hospital');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (24, 'Born outside this hospital');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (25, 'Transfer from Ambulatory Surgery Center');
INSERT INTO admission_source_lookup (admission_source_id, description) VALUES (26, 'Transfer from Hospice');

-- diagnosis_category_lookup (per Strack et al. 2014, Table 2)
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Circulatory', '390-459, 785');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Respiratory', '460-519, 786');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Digestive', '520-579, 787');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Diabetes', '250.xx');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Injury', '800-999');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Musculoskeletal', '710-739');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Genitourinary', '580-629, 788');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Neoplasms', '140-239');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Other', 'All remaining codes (infectious, mental, skin, blood, nervous, pregnancy, sense organ, congenital, E-V supplemental)');
INSERT INTO diagnosis_category_lookup (diagnosis_category, icd9_range_description) VALUES ('Unknown', 'Missing/unrecorded diagnosis code');

-- age_lookup
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[0-10)', 1);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[10-20)', 2);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[20-30)', 3);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[30-40)', 4);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[40-50)', 5);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[50-60)', 6);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[60-70)', 7);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[70-80)', 8);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[80-90)', 9);
INSERT INTO age_lookup (age_group, sort_order) VALUES ('[90-100)', 10);
