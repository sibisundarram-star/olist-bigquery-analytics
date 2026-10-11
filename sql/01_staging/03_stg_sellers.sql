CREATE OR REPLACE VIEW `{{project}}.{{staging}}.stg_sellers` AS
SELECT
  seller_id,
  seller_zip_code_prefix AS zip_code_prefix,
  INITCAP(seller_city)   AS city,
  seller_state           AS state
FROM `{{project}}.{{raw}}.sellers`;
