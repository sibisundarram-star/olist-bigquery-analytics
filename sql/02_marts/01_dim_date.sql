CREATE OR REPLACE TABLE `{{project}}.{{marts}}.dim_date` AS
SELECT
  d                                   AS date_key,
  EXTRACT(YEAR FROM d)                AS year,
  EXTRACT(QUARTER FROM d)             AS quarter,
  EXTRACT(MONTH FROM d)               AS month,
  FORMAT_DATE('%B', d)                AS month_name,
  DATE_TRUNC(d, MONTH)                AS month_start,
  EXTRACT(ISOWEEK FROM d)             AS iso_week,
  FORMAT_DATE('%A', d)                AS day_name,
  EXTRACT(DAYOFWEEK FROM d) IN (1, 7) AS is_weekend
FROM UNNEST(GENERATE_DATE_ARRAY('2016-09-01', '2018-12-31')) AS d;
