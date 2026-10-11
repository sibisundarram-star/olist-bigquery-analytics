CREATE OR REPLACE TABLE `{{project}}.{{marts}}.mart_seller_scorecard`
CLUSTER BY seller_state AS
WITH per_seller AS (
  SELECT
    i.seller_id,
    ANY_VALUE(i.seller_state)           AS seller_state,
    COUNT(DISTINCT i.order_id)          AS orders,
    COUNT(*)                            AS items_sold,
    SUM(i.price)                        AS revenue,
    AVG(i.price)                        AS avg_item_price,
    COUNT(DISTINCT i.category)          AS categories,
    AVG(o.review_score)                 AS avg_review_score,
    AVG(CAST(o.is_late AS INT64))       AS late_delivery_rate,
    AVG(o.delivery_days)                AS avg_delivery_days
  FROM `{{project}}.{{marts}}.fct_order_items` i
  JOIN `{{project}}.{{marts}}.fct_orders` o USING (order_id)
  WHERE i.is_valid_order
  GROUP BY i.seller_id
)
SELECT
  *,
  RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
  SAFE_DIVIDE(revenue, SUM(revenue) OVER ()) AS revenue_share
FROM per_seller;
