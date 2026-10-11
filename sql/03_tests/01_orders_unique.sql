-- fct_orders must have exactly one row per order_id (review/payment joins must not fan out)
SELECT order_id, COUNT(*) AS n
FROM `{{project}}.{{marts}}.fct_orders`
GROUP BY order_id
HAVING n > 1;
