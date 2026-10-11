CREATE OR REPLACE VIEW `{{project}}.{{staging}}.stg_order_items` AS
SELECT
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date AS shipping_limit_at,
  price,
  freight_value
FROM `{{project}}.{{raw}}.order_items`;
