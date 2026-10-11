CREATE OR REPLACE TABLE `{{project}}.{{marts}}.dim_products`
CLUSTER BY category AS
SELECT * FROM `{{project}}.{{staging}}.stg_products`;
