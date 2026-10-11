CREATE OR REPLACE VIEW `{{project}}.{{staging}}.stg_customers` AS
SELECT
  customer_id,                       -- one per order (changes every purchase)
  customer_unique_id,                -- the real, stable customer key
  customer_zip_code_prefix AS zip_code_prefix,
  INITCAP(customer_city)   AS city,
  customer_state           AS state
FROM `{{project}}.{{raw}}.customers`;
