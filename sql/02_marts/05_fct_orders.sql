-- Grain: one row per order. Partitioned by purchase date, clustered for common filters.
CREATE OR REPLACE TABLE `{{project}}.{{marts}}.fct_orders`
CLUSTER BY purchase_date, customer_state, order_status AS
WITH items AS (
  SELECT
    order_id,
    COUNT(*)                  AS items_count,
    COUNT(DISTINCT seller_id) AS sellers_count,
    SUM(price)                AS items_revenue,
    SUM(freight_value)        AS freight_revenue
  FROM `{{project}}.{{staging}}.stg_order_items`
  GROUP BY order_id
),
pay AS (
  SELECT
    order_id,
    SUM(payment_value)       AS payment_total,
    MAX(installments)        AS max_installments,
    ARRAY_AGG(payment_type ORDER BY payment_value DESC LIMIT 1)[OFFSET(0)] AS primary_payment_type
  FROM `{{project}}.{{staging}}.stg_payments`
  GROUP BY order_id
)
SELECT
  o.order_id,
  o.customer_id,
  c.customer_unique_id,
  c.state AS customer_state,
  o.order_status,
  o.order_status NOT IN ('canceled', 'unavailable') AS is_valid_order,
  o.purchased_at,
  DATE(o.purchased_at) AS purchase_date,
  o.approved_at,
  o.shipped_at,
  o.delivered_at,
  o.estimated_delivery_at,
  COALESCE(i.items_count, 0)      AS items_count,
  COALESCE(i.sellers_count, 0)    AS sellers_count,
  COALESCE(i.items_revenue, 0)    AS items_revenue,
  COALESCE(i.freight_revenue, 0)  AS freight_revenue,
  COALESCE(p.payment_total, 0)    AS payment_total,
  p.max_installments,
  p.primary_payment_type,
  r.review_score,
  ROUND(TIMESTAMP_DIFF(o.delivered_at, o.purchased_at, HOUR) / 24, 2) AS delivery_days,
  -- positive = late, negative = early (whole days, truncated toward zero)
  TIMESTAMP_DIFF(o.delivered_at, o.estimated_delivery_at, DAY)        AS delivery_delay_days,
  IF(o.delivered_at IS NULL, NULL, o.delivered_at > o.estimated_delivery_at) AS is_late
FROM `{{project}}.{{staging}}.stg_orders` o
JOIN `{{project}}.{{staging}}.stg_customers` c USING (customer_id)
LEFT JOIN items i USING (order_id)
LEFT JOIN pay p USING (order_id)
LEFT JOIN `{{project}}.{{staging}}.stg_reviews` r USING (order_id);
