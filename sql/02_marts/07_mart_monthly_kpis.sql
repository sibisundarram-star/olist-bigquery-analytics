-- Note: 2016 is very sparse and Sep/Oct 2018 are incomplete in the source data.
CREATE OR REPLACE TABLE `{{project}}.{{marts}}.mart_monthly_kpis` AS
WITH monthly AS (
  SELECT
    DATE_TRUNC(purchase_date, MONTH)  AS month,
    COUNT(*)                          AS orders,
    COUNT(DISTINCT customer_unique_id) AS customers,
    SUM(items_revenue)                AS items_revenue,
    SUM(freight_revenue)              AS freight_revenue,
    AVG(items_revenue)                AS avg_order_value,
    AVG(review_score)                 AS avg_review_score,
    AVG(CAST(is_late AS INT64))       AS late_delivery_rate
  FROM `{{project}}.{{marts}}.fct_orders`
  WHERE is_valid_order
  GROUP BY month
)
SELECT
  *,
  SAFE_DIVIDE(items_revenue - LAG(items_revenue) OVER (ORDER BY month),
              LAG(items_revenue) OVER (ORDER BY month)) AS revenue_mom_growth
FROM monthly;
