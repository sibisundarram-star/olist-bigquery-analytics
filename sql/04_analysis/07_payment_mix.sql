SELECT
  primary_payment_type,
  COUNT(*)                         AS orders,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders,
  ROUND(AVG(payment_total), 2)     AS avg_order_payment,
  ROUND(AVG(max_installments), 1)  AS avg_installments
FROM `{{project}}.{{marts}}.fct_orders`
WHERE is_valid_order AND primary_payment_type IS NOT NULL
GROUP BY primary_payment_type
ORDER BY orders DESC;
