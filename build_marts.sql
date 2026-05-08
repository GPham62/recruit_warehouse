-- duckdb rw_marts.duckdb -c ".read build_marts.sql"
-- Create star schema tables
.read create_tables_rw.sql

-- Load data from CSV files into tables
.read load_schema_rw.sql

-- Mart - Create flat mart
.read create_flat_mart.sql

-- Mart - Create skills demand mart
.read create_skills_mart.sql