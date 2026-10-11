SELECT
  segment,
  COUNT(*)                         AS customers,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers,
  ROUND(AVG(recency_days), 0)      AS avg_recency_days,
  ROUND(AVG(monetary), 2)          AS avg_spend,
  ROUND(SUM(monetary), 0)          AS total_revenue,
  ROUND(100 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_of_revenue
FROM `{{project}}.{{marts}}.mart_customer_rfm`
GROUP BY segment
ORDER BY total_revenue DESC;
