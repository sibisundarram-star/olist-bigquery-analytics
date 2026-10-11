-- The source has 8 known "delivered" orders with no delivery timestamp.
-- Fail only if it gets worse than that (e.g. after a bad reload).
SELECT n AS delivered_without_timestamp
FROM (
  SELECT COUNT(*) AS n
  FROM `{{project}}.{{marts}}.fct_orders`
  WHERE order_status = 'delivered' AND delivered_at IS NULL
)
WHERE n > 8;
