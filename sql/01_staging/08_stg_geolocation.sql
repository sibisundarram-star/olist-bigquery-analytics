-- Source has ~1M rows for ~19k zip prefixes. Collapse to one centroid per prefix.
CREATE OR REPLACE VIEW `{{project}}.{{staging}}.stg_geolocation` AS
SELECT
  geolocation_zip_code_prefix AS zip_code_prefix,
  AVG(geolocation_lat) AS lat,
  AVG(geolocation_lng) AS lng,
  APPROX_TOP_COUNT(INITCAP(geolocation_city), 1)[OFFSET(0)].value AS city,
  APPROX_TOP_COUNT(geolocation_state, 1)[OFFSET(0)].value         AS state
FROM `{{project}}.{{raw}}.geolocation`
GROUP BY zip_code_prefix;
