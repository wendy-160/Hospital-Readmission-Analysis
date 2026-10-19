-- Hospital Readmission Reporting & Utilization Analysis
-- Schema DDL (MySQL)
-- Source: Diabetes 130-US Hospitals dataset (Strack et al., 2014)

CREATE DATABASE IF NOT EXISTS hospital_readmission;
USE hospital_readmission;

-- LOOKUP TABLES   

CREATE TABLE age_lookup (
    age_group       VARCHAR(10)     PRIMARY KEY, -- e.g, '[70-80]'
    sort_order      TINYINT         NOT NULL     -- 1-10, for chart ordering
);

CREATE TABLE admission_type_lookup (
    admission_type_id       TINYINT         PRIMARY KEY,
    description             VARCHAR(50)     NOT NULL
);

CREATE TABLE discharge_disposition_lookup (
    discharge_disposition_id    TINYINT         PRIMARY KEY,
    description                 VARCHAR(150)    NOT NULL,
    is_terminal_discharge       BOOLEAN         NOT NULL DEFAULT FALSE -- TRUE for expired/hospice codes (11, 13, 14, 19, 20, 21)
);

CREATE TABLE admission_source_lookup (
    admission_source_id         TINYINT         PRIMARY KEY,
    description                 VARCHAR(100)    NOT NULL
);

CREATE TABLE diagnosis_category_lookup (
    diagnosis_category          VARCHAR (30)    PRIMARY KEY, -- e.g. 'Circulatory'
    icd9_range_description      VARCHAR(150)    -- e.g. '390-459, 785'
);

-- CORE TABLES  

CREATE TABLE patients (
    patient_nbr     INT             PRIMARY KEY,
    race            VARCHAR(20)     NOT NULL DEFAULT 'Unknown',
    gender          VARCHAR(10)     NOT NULL    
);

CREATE TABLE encounters (
    encounter_id                INT         PRIMARY KEY,
    patient_nbr                 INT         NOT NULL, 
    admission_type_id           TINYINT,
    discharge_disposition_id    TINYINT,
    admission_source_id         TINYINT, 
    age_group                   VARCHAR(10), -- patient's age AT THE TIME of this encounter (time-varying, not a patient-level trait)
    medical_specialty           VARCHAR(60) NOT NULL DEFAULT 'Unknown',
    payer_code                  VARCHAR(20) NOT NULL DEFAULT 'Unknown',
    time_in_hospital            TINYINT     NOT NULL,
    num_lab_procedures          SMALLINT    NOT NULL,
    num_procedures              TINYINT     NOT NULL,
    num_medications             SMALLINT    NOT NULL,
    number_outpatient           SMALLINT    NOT NULL,
    number_emergency            SMALLINT    NOT NULL,
    number_inpatient            SMALLINT    NOT NULL,
    number_diagnoses            TINYINT     NOT NULL,
    max_glu_serum               VARCHAR(10) NOT NULL DEFAULT 'None',
    A1Cresult                   VARCHAR(10) NOT NULL DEFAULT 'None',
    change_flag                 VARCHAR(10) NOT NULL,   -- 'Ch' / 'No'
    diabetes_med                VARCHAR(5)  NOT NULL,   -- 'Yes' / 'No'
    readmitted                  VARCHAR(5)  NOT NULL,   -- '<30' / '>30 / 'NO'
    FOREIGN KEY (patient_nbr) REFERENCES patients(patient_nbr),
    FOREIGN KEY (admission_type_id) REFERENCES admission_type_lookup(admission_type_id),
    FOREIGN KEY (discharge_disposition_id) REFERENCES discharge_disposition_lookup(discharge_disposition_id),
    FOREIGN KEY (admission_source_id) REFERENCES admission_source_lookup(admission_source_id),
    FOREIGN KEY (age_group) REFERENCES age_lookup(age_group)        
);

CREATE TABLE diagnoses (
    diagnosis_id            INT AUTO_INCREMENT PRIMARY KEY,
    encounter_id           INT         NOT NULL,
    diagnosis_position      TINYINT     NOT NULL,       -- 1, 2, or 3
    icd9_code               VARCHAR(10) NOT NULL DEFAULT 'Unknown',
    diagnosis_category      VARCHAR(30),
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id),
    FOREIGN KEY (diagnosis_category) REFERENCES diagnosis_category_lookup(diagnosis_category),
    UNIQUE KEY uq_encounter_position (encounter_id, diagnosis_position)
);

CREATE TABLE medications (
    medication_id       INT AUTO_INCREMENT PRIMARY KEY,
    encounter_id        INT         NOT NULL,
    drug_name           VARCHAR(30) NOT NULL, 
    status              VARCHAR(10) NOT NULL, -- No / Steady / Up / Down
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id),
    UNIQUE KEY uq_encounter_drug (encounter_id, drug_name)
);

-- Indexes to support common reporting queries

CREATE INDEX idx_encounters_patient ON encounters(patient_nbr);
CREATE INDEX idx_encounters_readmitted ON encounters(readmitted);
CREATE INDEX idx_diagnoses_category ON diagnoses(diagnosis_category);
CREATE INDEX idx_medications_status ON medications(status);