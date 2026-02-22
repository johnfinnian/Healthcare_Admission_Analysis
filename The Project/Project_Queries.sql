
CREATE DATABASE Healthcare_db;

CREATE TABLE staging (
Name TEXT,
Age TEXT,
Gender TEXT,
Blood_Type TEXT,
Medical_Condition TEXT,
Date_of_Admission TEXT,
Doctor TEXT,
Hospital TEXT,
Insurance_Provider TEXT,
Billing_Amount TEXT,
Room_Number TEXT,
Admission_Type TEXT,
Discharge_Date TEXT,
Medication TEXT,
Test_Results TEXT
);

\copy staging FROM 'C:\Users\chimc\Documents\2_Healthcare_Project\healthcare_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');



CREATE SCHEMA IF NOT EXISTS dim;

CREATE TABLE dim.dim_date (
    date_id        INTEGER PRIMARY KEY,      -- YYYYMMDD
    full_date      DATE NOT NULL UNIQUE,
    year           INTEGER NOT NULL,
    quarter        INTEGER NOT NULL,
    month          INTEGER NOT NULL,
    month_name     TEXT NOT NULL,
    week           INTEGER NOT NULL,
    day            INTEGER NOT NULL,
    day_of_week    INTEGER NOT NULL,
    day_name       TEXT NOT NULL,
    is_weekend     BOOLEAN NOT NULL
);


INSERT INTO dim.dim_date (
    date_id,
    full_date,
    year,
    quarter,
    month,
    month_name,
    week,
    day,
    day_of_week,
    day_name,
    is_weekend
)

SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_id,
    d AS full_date,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    TO_CHAR(d, 'Month'),
    EXTRACT(WEEK FROM d)::INTEGER,
    EXTRACT(DAY FROM d)::INTEGER,
    EXTRACT(DOW FROM d)::INTEGER,
    TO_CHAR(d, 'Day'),
    CASE WHEN EXTRACT(DOW FROM d) IN (0,6) THEN TRUE ELSE FALSE END
FROM generate_series(
    '2015-01-01'::DATE,
    '2030-12-31'::DATE,
    INTERVAL '1 day'
) AS d;


CREATE TABLE dim.dim_date (
    date_id        INTEGER PRIMARY KEY,      -- YYYYMMDD
    full_date      DATE NOT NULL UNIQUE,
    year           INTEGER NOT NULL,
    quarter        INTEGER NOT NULL,
    month          INTEGER NOT NULL,
    month_name     TEXT NOT NULL,
    week           INTEGER NOT NULL,
    day            INTEGER NOT NULL,
    day_of_week    INTEGER NOT NULL,
    day_name       TEXT NOT NULL,
    is_weekend     BOOLEAN NOT NULL
);


INSERT INTO dim.dim_date (
    date_id,
    full_date,
    year,
    quarter,
    month,
    month_name,
    week,
    day,
    day_of_week,
    day_name,
    is_weekend
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_id,
    d AS full_date,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    TO_CHAR(d, 'Month'),
    EXTRACT(WEEK FROM d)::INTEGER,
    EXTRACT(DAY FROM d)::INTEGER,
    EXTRACT(DOW FROM d)::INTEGER,
    TO_CHAR(d, 'Day'),
    CASE WHEN EXTRACT(DOW FROM d) IN (0,6) THEN TRUE ELSE FALSE END
FROM generate_series(
    '2015-01-01'::DATE,
    '2030-12-31'::DATE,
    INTERVAL '1 day'
) AS d;     


CREATE TABLE dim.dim_hospital (
    hospital_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_name  TEXT NOT NULL UNIQUE
);


INSERT INTO dim.dim_hospital (hospital_name)
SELECT DISTINCT hospital
FROM staging
WHERE hospital IS NOT NULL
ORDER BY hospital;


CREATE TABLE dim.dim_insurance (
    insurance_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    insurance_provider  TEXT NOT NULL UNIQUE
);


CREATE TABLE dim.dim_room (
    room_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hospital_id BIGINT NOT NULL,
    room_number TEXT NOT NULL,
    UNIQUE (hospital_id, room_number),
    FOREIGN KEY (hospital_id) REFERENCES dim.dim_hospital(hospital_id)
);

INSERT INTO dim.dim_room (hospital_id, room_number)
SELECT DISTINCT
    dh.hospital_id,
    s.room_number
FROM staging s
JOIN dim.dim_hospital dh
    ON dh.hospital_name = s.hospital
WHERE s.room_number IS NOT NULL;



INSERT INTO dim.dim_insurance (insurance_provider)
SELECT DISTINCT insurance_provider
FROM staging
WHERE insurance_provider IS NOT NULL
ORDER BY insurance_provider;


CREATE TABLE dim.dim_condition (
    condition_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medical_condition TEXT NOT NULL UNIQUE
);

INSERT INTO dim.dim_condition (medical_condition)
SELECT DISTINCT medical_condition
FROM staging
WHERE medical_condition IS NOT NULL
ORDER BY medical_condition;


CREATE TABLE dim.dim_admission_type (
    admission_type_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    admission_type    TEXT NOT NULL UNIQUE
);

INSERT INTO dim.dim_admission_type (admission_type)
SELECT DISTINCT admission_type
FROM staging
WHERE admission_type IS NOT NULL;


CREATE TABLE dim.dim_patient (
    patient_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_name TEXT NOT NULL,
    age INTEGER,
    gender TEXT,
    blood_type TEXT
);

INSERT INTO dim.dim_patient (patient_name, age, gender, blood_type)
SELECT DISTINCT
    name,
    age::INTEGER,
    gender,
    blood_type
FROM staging
WHERE name IS NOT NULL;



CREATE SCHEMA fact


CREATE TABLE fact.fact_admissions (

    admission_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id BIGINT NOT NULL,
    admission_date_id INTEGER NOT NULL,
    discharge_date_id INTEGER,

    hospital_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL,
    insurance_id BIGINT NOT NULL,
    condition_id BIGINT NOT NULL,
    admission_type_id BIGINT NOT NULL,

    length_of_stay INTEGER,
    billing_amount NUMERIC(12,2),

    FOREIGN KEY (patient_id) REFERENCES dim.dim_patient(patient_id),
    FOREIGN KEY (admission_date_id) REFERENCES dim.dim_date(date_id),
    FOREIGN KEY (discharge_date_id) REFERENCES dim.dim_date(date_id),
    FOREIGN KEY (hospital_id) REFERENCES dim.dim_hospital(hospital_id),
    FOREIGN KEY (room_id) REFERENCES dim.dim_room(room_id),
    FOREIGN KEY (insurance_id) REFERENCES dim.dim_insurance(insurance_id),
    FOREIGN KEY (condition_id) REFERENCES dim.dim_condition(condition_id),
    FOREIGN KEY (admission_type_id) REFERENCES dim.dim_admission_type(admission_type_id)
);


INSERT INTO fact.fact_admissions (
    admission_date_id,
    discharge_date_id,
    room_id,
    patient_id,
    hospital_id,
    insurance_id,
    condition_id,
    admission_type_id,
    length_of_stay,
    billing_amount
)

SELECT
    -- 1 Admission Date
    TO_CHAR(s.date_of_admission::DATE, 'YYYYMMDD')::INTEGER,

    -- 2 Discharge Date
    TO_CHAR(s.discharge_date::DATE, 'YYYYMMDD')::INTEGER,

    -- 3 Room ID  ✅ FIXED
    dr.room_id,

    -- 4 Patient ID
    dp.patient_id,

    -- 5 Hospital ID
    dh.hospital_id,

    -- 6 Insurance
    di.insurance_id,

    -- 7 Condition
    dc.condition_id,

    -- 8 Admission Type
    dat.admission_type_id,

    -- 9 LOS
    (s.discharge_date::DATE - s.date_of_admission::DATE),

    -- 10 Billing
    s.billing_amount::NUMERIC(12,2)

FROM staging s

JOIN dim.dim_patient dp
    ON dp.patient_name = s.name

JOIN dim.dim_hospital dh
    ON dh.hospital_name = s.hospital

JOIN dim.dim_insurance di
    ON di.insurance_provider = s.insurance_provider

JOIN dim.dim_condition dc
    ON dc.medical_condition = s.medical_condition

JOIN dim.dim_admission_type dat
    ON dat.admission_type = s.admission_type

JOIN dim.dim_room dr
    ON dr.room_number = s.room_number
   AND dr.hospital_id = dh.hospital_id;


