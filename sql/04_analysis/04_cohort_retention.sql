-- Monthly acquisition cohorts: % of each cohort that orders again N months later.
WITH valid AS (
  SELECT customer_unique_id, DATE_TRUNC(purchase_date, MONTH) AS order_month
  FROM `{{project}}.{{marts}}.fct_orders`
  WHERE is_valid_order
),
cohorts AS (
  SELECT customer_unique_id, MIN(order_month) AS cohort_month
  FROM valid GROUP BY customer_unique_id
),
sizes AS (
  SELECT cohort_month, COUNT(*) AS cohort_size FROM cohorts GROUP BY cohort_month
),
activity AS (
  SELECT
    c.cohort_month,
    DATE_DIFF(v.order_month, c.cohort_month, MONTH) AS months_since,
    COUNT(DISTINCT v.customer_unique_id) AS active_customers
  FROM valid v
  JOIN cohorts c USING (customer_unique_id)
  GROUP BY cohort_month, months_since
)
SELECT
  a.cohort_month,
  s.cohort_size,
  a.months_since,
  a.active_customers,
  ROUND(100 * a.active_customers / s.cohort_size, 2) AS retention_pct
FROM activity a
JOIN sizes s USING (cohort_month)
WHERE a.cohort_month BETWEEN '2017-01-01' AND '2018-01-01'
  AND a.months_since BETWEEN 0 AND 12
ORDER BY a.cohort_month, a.months_since;
