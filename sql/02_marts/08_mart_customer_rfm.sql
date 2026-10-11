-- Recency / Frequency / Monetary segmentation per real customer.
-- Frequency is bucketed manually (1, 2, 3+) because ~97% of customers ordered once,
-- which makes quantile scoring meaningless for that dimension.
CREATE OR REPLACE TABLE `{{project}}.{{marts}}.mart_customer_rfm`
CLUSTER BY segment AS
WITH ref AS (
  SELECT DATE_ADD(MAX(purchase_date), INTERVAL 1 DAY) AS ref_date
  FROM `{{project}}.{{marts}}.fct_orders`
),
base AS (
  SELECT
    customer_unique_id,
    DATE_DIFF((SELECT ref_date FROM ref), MAX(purchase_date), DAY) AS recency_days,
    COUNT(*)           AS frequency,
    SUM(items_revenue) AS monetary
  FROM `{{project}}.{{marts}}.fct_orders`
  WHERE is_valid_order
  GROUP BY customer_unique_id
),
scored AS (
  SELECT
    *,
    6 - NTILE(5) OVER (ORDER BY recency_days) AS r_score,   -- 5 = most recent
    LEAST(frequency, 3)                       AS f_score,
    NTILE(5) OVER (ORDER BY monetary)         AS m_score    -- 5 = highest spend
  FROM base
)
SELECT
  *,
  CASE
    WHEN f_score >= 2 AND r_score >= 4 THEN 'Loyal - active'
    WHEN f_score >= 2                  THEN 'Repeat - lapsing'
    WHEN r_score >= 4 AND m_score >= 4 THEN 'New - high value'
    WHEN r_score >= 4                  THEN 'New'
    WHEN r_score <= 2 AND m_score >= 4 THEN 'At risk - high value'
    ELSE 'Dormant'
  END AS segment
FROM scored;
