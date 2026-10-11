-- Grain: one row per order line item.
CREATE OR REPLACE TABLE `{{project}}.{{marts}}.fct_order_items`
CLUSTER BY purchase_date, seller_id, category AS
SELECT
  oi.order_id,
  oi.order_item_id,
  oi.product_id,
  oi.seller_id,
  o.customer_unique_id,
  p.category,
  s.state          AS seller_state,
  o.customer_state,
  o.order_status,
  o.is_valid_order,
  o.purchased_at,
  o.purchase_date,
  oi.shipping_limit_at,
  oi.price,
  oi.freight_value,
  oi.price + oi.freight_value AS gross_item_value
FROM `{{project}}.{{staging}}.stg_order_items` oi
JOIN `{{project}}.{{marts}}.fct_orders` o USING (order_id)
LEFT JOIN `{{project}}.{{staging}}.stg_products` p USING (product_id)
LEFT JOIN `{{project}}.{{staging}}.stg_sellers` s USING (seller_id);
