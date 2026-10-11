-- Which categories drive revenue? Cumulative share shows the 80/20 cutoff.
WITH cat AS (
  SELECT category, SUM(price) AS revenue, COUNT(DISTINCT order_id) AS orders
  FROM `{{project}}.{{marts}}.fct_order_items`
  WHERE is_valid_order
  GROUP BY category
)
SELECT
  category,
  ROUND(revenue, 0) AS revenue_brl,
  orders,
  ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS share_pct,
  ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER (), 2) AS cumulative_share_pct
FROM cat
ORDER BY revenue DESC
LIMIT 25;
