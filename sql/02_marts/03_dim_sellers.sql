CREATE OR REPLACE TABLE `{{project}}.{{marts}}.dim_sellers`
CLUSTER BY state AS
SELECT
  s.seller_id,
  s.zip_code_prefix,
  s.city,
  s.state,
  g.lat,
  g.lng
FROM `{{project}}.{{staging}}.stg_sellers` s
LEFT JOIN `{{project}}.{{staging}}.stg_geolocation` g USING (zip_code_prefix);
