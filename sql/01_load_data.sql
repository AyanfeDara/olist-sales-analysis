-- =====================================================================
-- 01_load_data.sql
-- Loads the nine Olist CSV files into the tables from 00_create_schema.sql.
--
-- Run it in the psql tool (pgAdmin: right-click the "olist" database,
-- then "PSQL Tool"). First move into the folder that holds the CSVs:
--
--     \cd 'C:/Users/<you>/olist-sales-analysis/data/raw'
--     \i 'C:/Users/<you>/olist-sales-analysis/sql/01_load_data.sql'
--
-- Use forward slashes in Windows paths. Parent tables load first,
-- so the foreign keys are satisfied.
-- =====================================================================

\echo 'Loading category_translation...'
\copy category_translation FROM 'product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\echo 'Loading customers...'
\copy customers FROM 'olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\echo 'Loading geolocation (about 1 million rows, takes a moment)...'
\copy geolocation FROM 'olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\echo 'Loading sellers...'
\copy sellers FROM 'olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\echo 'Loading products...'
\copy products FROM 'olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\echo 'Loading orders...'
\copy orders FROM 'olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\echo 'Loading order_items...'
\copy order_items FROM 'olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\echo 'Loading order_payments...'
\copy order_payments FROM 'olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

\echo 'Loading order_reviews...'
\copy order_reviews FROM 'olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

ANALYZE;

\echo 'Done. Now run sql/02_data_checks.sql.'
