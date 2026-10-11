-- Revenue, freight burden and delivery speed by customer state
SELECT
  customer_state,
  COUNT(*)                                   AS orders,
  ROUND(SUM(items_revenue), 0)               AS revenue_brl,
  ROUND(100 * SAFE_DIVIDE(SUM(freight_revenue), SUM(items_revenue)), 1) AS freight_pct_of_item_value,
  ROUND(AVG(delivery_days), 1)               AS avg_delivery_days,
  ROUND(100 * AVG(CAST(is_late AS INT64)), 1) AS late_pct,
  ROUND(AVG(review_score), 2)                AS avg_review
FROM `{{project}}.{{marts}}.fct_orders`
WHERE is_valid_order
GROUP BY customer_state
ORDER BY revenue_brl DESC;
