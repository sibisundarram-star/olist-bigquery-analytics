-- How much does late delivery hurt customer satisfaction?
SELECT
  CASE
    WHEN NOT is_late          THEN '1. On time / early'
    WHEN delivery_delay_days < 3 THEN '2. Late < 3 days'
    WHEN delivery_delay_days < 7 THEN '3. Late 3-6 days'
    ELSE                           '4. Late 7+ days'
  END AS delivery_bucket,
  COUNT(*)                         AS orders,
  ROUND(AVG(review_score), 2)      AS avg_review_score,
  ROUND(100 * COUNTIF(review_score <= 2) / COUNT(*), 1) AS pct_bad_reviews
FROM `{{project}}.{{marts}}.fct_orders`
WHERE order_status = 'delivered' AND is_late IS NOT NULL AND review_score IS NOT NULL
GROUP BY delivery_bucket
ORDER BY delivery_bucket;
