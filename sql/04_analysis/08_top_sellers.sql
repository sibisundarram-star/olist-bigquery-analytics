-- Top 20 sellers, with the quality signals that matter for marketplace health
SELECT
  revenue_rank,
  seller_id,
  seller_state,
  orders,
  ROUND(revenue, 0)                  AS revenue_brl,
  ROUND(100 * revenue_share, 2)      AS share_pct,
  ROUND(avg_review_score, 2)         AS avg_review,
  ROUND(100 * late_delivery_rate, 1) AS late_pct,
  ROUND(avg_delivery_days, 1)        AS avg_delivery_days
FROM `{{project}}.{{marts}}.mart_seller_scorecard`
ORDER BY revenue_rank
LIMIT 20;
