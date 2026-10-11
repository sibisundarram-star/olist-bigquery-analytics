-- Monthly revenue trend with growth and quality KPIs
SELECT
  month,
  orders,
  customers,
  ROUND(items_revenue, 0)            AS revenue_brl,
  IF(month = '2017-01-01', NULL, ROUND(revenue_mom_growth * 100, 1)) AS mom_growth_pct,
  ROUND(avg_order_value, 2)          AS aov,
  ROUND(avg_review_score, 2)         AS avg_review,
  ROUND(late_delivery_rate * 100, 1) AS late_pct
FROM `{{project}}.{{marts}}.mart_monthly_kpis`
WHERE month >= '2017-01-01' AND month <= '2018-08-01'
ORDER BY month;
