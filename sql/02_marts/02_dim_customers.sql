-- Grain: one row per real customer (customer_unique_id), not per customer_id.
CREATE OR REPLACE TABLE `{{project}}.{{marts}}.dim_customers`
CLUSTER BY state AS
WITH cust_orders AS (
  SELECT c.customer_unique_id, c.zip_code_prefix, c.city, c.state,
         o.order_id, o.purchased_at
  FROM `{{project}}.{{staging}}.stg_customers` c
  LEFT JOIN `{{project}}.{{staging}}.stg_orders` o USING (customer_id)
),
agg AS (
  SELECT
    customer_unique_id,
    -- location from the customer's most recent order
    ARRAY_AGG(STRUCT(zip_code_prefix, city, state)
              ORDER BY purchased_at DESC LIMIT 1)[OFFSET(0)] AS loc,
    MIN(purchased_at)          AS first_order_at,
    MAX(purchased_at)          AS last_order_at,
    COUNT(DISTINCT order_id)   AS orders_count
  FROM cust_orders
  GROUP BY customer_unique_id
)
SELECT
  a.customer_unique_id,
  a.loc.zip_code_prefix AS zip_code_prefix,
  a.loc.city            AS city,
  a.loc.state           AS state,
  g.lat, g.lng,
  a.first_order_at,
  a.last_order_at,
  a.orders_count,
  a.orders_count > 1    AS is_repeat_customer
FROM agg a
LEFT JOIN `{{project}}.{{staging}}.stg_geolocation` g
  ON g.zip_code_prefix = a.loc.zip_code_prefix;
