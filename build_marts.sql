-- Create star schema tables
.read create_tables_rw.sql

-- Load data from CSV files into tables
.read load_schema_rw.sql

-- Mart - Create flat mart
.read create_flat_mart.sql