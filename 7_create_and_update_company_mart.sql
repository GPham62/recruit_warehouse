DROP SCHEMA IF EXISTS company_mart CASCADE;

CREATE SCHEMA company_mart;

SELECT '=== Loading Company Location Dim ===' AS info;

CREATE TABLE company_mart.company_dim (
    company_id INTEGER PRIMARY KEY,
    name VARCHAR
);

INSERT INTO company_mart.company_dim(company_id, name)
SELECT
    company_id,
    name
FROM
    company_dim;

SELECT * FROM company_dim;

CREATE TABLE company_mart.location_dim(
    location_id INTEGER PRIMARY KEY,
    job_country VARCHAR,
    job_location VARCHAR
);

CREATE TABLE company_mart.company_location_dim (
    company_id INTEGER,
    location_id INTEGER,
    PRIMARY KEY (company_id, location_id),
    FOREIGN KEY (company_id) REFERENCES company_mart.company_dim(company_id),
    FOREIGN KEY (location_id) REFERENCES company_mart.location_dim(location_id)
);

WITH location_flat AS (
    SELECT DISTINCT 
        job_country,
        job_location
    FROM
        job_postings_fact
    WHERE job_country IS NOT NULL AND job_location IS NOT NULL
)
INSERT INTO company_mart.location_dim (location_id, job_country, job_location)
SELECT
    ROW_NUMBER() OVER(ORDER BY job_country, job_location) AS location_id,
    job_country,
    job_location
FROM
    location_flat;

SELECT '=== Location Dimension Sample ===' AS info;
SELECT * FROM company_mart.location_dim LIMIT 5;

INSERT INTO company_mart.company_location_dim(company_id, location_id)
SELECT DISTINCT
    jpf.company_id,
    ld.location_id
FROM
    job_postings_fact AS jpf
JOIN company_mart.location_dim AS ld
    ON jpf.job_location = ld.job_location
    AND jpf.job_country = ld.job_country
WHERE jpf.company_id IS NOT NULL
    AND jpf.job_country IS NOT NULL
    AND jpf.job_location IS NOT NULL;

SELECT '=== Company Location Dimension Sample ===' AS info;
SELECT * FROM company_mart.company_location_dim LIMIT 5;

SELECT '=== Loading Job Title Dim ===' AS info;
CREATE TABLE company_mart.job_title_short_dim(
    job_title_short_id INTEGER PRIMARY KEY,
    job_title_short VARCHAR
);

CREATE TABLE company_mart.job_title_dim(
    job_title_id INTEGER PRIMARY KEY,
    job_title VARCHAR
);

CREATE TABLE company_mart.job_title_bridge(
    job_title_short_id INTEGER,
    job_title_id INTEGER,
    PRIMARY KEY (job_title_id, job_title_short_id),
    FOREIGN KEY (job_title_id) REFERENCES company_mart.job_title_dim(job_title_id),
    FOREIGN KEY (job_title_short_id) REFERENCES company_mart.job_title_short_dim(job_title_short_id)
);

INSERT INTO company_mart.job_title_dim(job_title_id, job_title)
SELECT
    ROW_NUMBER() OVER(ORDER BY job_title) AS job_title_id,
    job_title
FROM (
    SELECT DISTINCT
        job_title
    FROM job_postings_fact
) AS job_title_flat;

SELECT '=== Job Title Dimension Sample ===' AS info;
SELECT * FROM company_mart.job_title_dim LIMIT 5;

INSERT INTO company_mart.job_title_short_dim(job_title_short_id, job_title_short)
SELECT
    ROW_NUMBER() OVER(ORDER BY job_title_short) AS job_title_short_id,
    job_title_short
FROM
(
    SELECT DISTINCT
        job_title_short
    FROM
        job_postings_fact
    WHERE job_title_short IS NOT NULL
) AS t;

SELECT '=== Job Title Short Dimension Sample ===' AS info;
SELECT * FROM company_mart.job_title_short_dim LIMIT 5;

INSERT INTO company_mart.job_title_bridge(job_title_short_id, job_title_id)
SELECT DISTINCT
    jts.job_title_short_id,
    jt.job_title_id
FROM job_postings_fact AS jpf
JOIN company_mart.job_title_dim AS jt
    ON jpf.job_title = jt.job_title
JOIN company_mart.job_title_short_dim AS jts
    ON jpf.job_title_short = jts.job_title_short;
    
SELECT '=== Job Title Bridge Sample ===' AS info;
SELECT * FROM company_mart.job_title_bridge LIMIT 5;

SELECT '=== Duplicate Date Month Dimension Table ===' AS info;
CREATE TABLE company_mart.date_month_dim(
    month_start_date DATE PRIMARY KEY,
    year INTEGER,
    month INTEGER,
    quarter INTEGER,
    quarter_name VARCHAR,
    year_quarter VARCHAR
);

INSERT INTO company_mart.date_month_dim(
    month_start_date,
    year,
    month,
    quarter,
    quarter_name,
    year_quarter
)
SELECT
    month_start_date,
    year,
    month,
    quarter,
    quarter_name,
    year_quarter
FROM
    skills_mart.date_month_dim;

SELECT '=== Loading Fact Company Hiring Monthly Table ===' As info;
CREATE TABLE company_mart.fact_company_hiring_monthly(
    company_id INTEGER,
    job_title_short_id INTEGER,
    month_start_date DATE,
    job_country VARCHAR,
    postings_count INTEGER,
    median_salary_year DOUBLE,
    min_salary_year DOUBLE,
    max_salary_year DOUBLE,
    remote_share DOUBLE,
    health_insurance_share DOUBLE,
    no_degree_mention_share DOUBLE,
    PRIMARY KEY (company_id, job_title_short_id, month_start_date, job_country),
    FOREIGN KEY (company_id) REFERENCES company_mart.company_dim(company_id),
    FOREIGN KEY (job_title_short_id) REFERENCES company_mart.job_title_short_dim(job_title_short_id),
    FOREIGN KEY (month_start_date) REFERENCES company_mart.date_month_dim(month_start_date)
);

INSERT INTO company_mart.fact_company_hiring_monthly (
    company_id,
    job_title_short_id,
    month_start_date,
    job_country,
    postings_count,
    median_salary_year,
    min_salary_year,
    max_salary_year,
    remote_share,
    health_insurance_share,
    no_degree_mention_share
)
SELECT
    jpf.company_id,
    jts.job_title_short_id,
    DATE_TRUNC('month', jpf.job_posted_date)::DATE,
    jpf.job_country,
    COUNT(*) AS postings_count,
    MEDIAN(jpf.salary_year_avg) AS median_salary_year,
    MIN(jpf.salary_year_avg) AS min_salary_year,
    MAX(jpf.salary_year_avg) AS max_salary_year,
    AVG(jpf.job_work_from_home::DOUBLE)::DECIMAL(10,2) AS remote_share,
    AVG(jpf.job_health_insurance::DOUBLE)::DECIMAL(10,2) AS health_insurance_share,
    AVG(jpf.job_no_degree_mention::DOUBLE)::DECIMAL(10,2) AS no_degree_mention_share
FROM
    job_postings_fact AS jpf
JOIN company_mart.company_dim AS cd
    ON jpf.company_id = cd.company_id
JOIN company_mart.job_title_short_dim AS jts
    ON jpf.job_title_short = jts.job_title_short
JOIN company_mart.date_month_dim AS dmd
    ON DATE_TRUNC('month', jpf.job_posted_date)::DATE = dmd.month_start_date
WHERE
    jpf.job_country IS NOT NULL
GROUP BY
    jpf.company_id,
    jts.job_title_short_id,
    DATE_TRUNC('month', jpf.job_posted_date)::DATE,
    jpf.job_country;

SELECT '=== Fact Company Hiring Monthly Sample ===' AS info;
SELECT * FROM company_mart.fact_company_hiring_monthly LIMIT 5;