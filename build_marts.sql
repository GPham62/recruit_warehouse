-- duckdb md:rw_marts -c ".read build_marts.sql"
-- Create star schema tables
.read 1_create_tables_rw.sql

-- Load data from CSV files into tables
.read 2_load_schema_rw.sql

-- Mart - Create flat mart
.read 3_create_flat_mart.sql

-- Mart - Create skills demand mart
.read 4_create_skills_mart.sql

-- Mart - Create priority mart
.read 5_create_priority_mart.sql

-- Mart - Update priority mart
.read 6_update_priority_mart.sql

-- Mart - Create And Update company mart
.read 7_create_and_update_company_mart.sql