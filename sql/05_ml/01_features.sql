CREATE OR REPLACE TABLE `{{project}}.{{marts}}.ml_review_features` AS
WITH main_item AS (
  SELECT
    order_id,
    ARRAY_AGG(STRUCT(product_id, seller_id, category, seller_state)
              ORDER BY price DESC, order_item_id LIMIT 1)[OFFSET(0)] AS m
  FROM `{{project}}.{{marts}}.fct_order_items`
  GROUP BY order_id
)
SELECT
  o.order_id,
  o.purchase_date,
  IF(o.purchase_date >= '2018-03-01', 'test', 'train') AS split,
  IF(o.review_score <= 2, 1, 0) AS is_bad_review,
  o.customer_state,
  mi.m.seller_state                          AS seller_state,
  o.customer_state = mi.m.seller_state       AS same_state,
  ROUND(ST_DISTANCE(ST_GEOGPOINT(c.lng, c.lat),
                    ST_GEOGPOINT(s.lng, s.lat)) / 1000, 1) AS distance_km,
  mi.m.category                              AS category,
  o.items_revenue                            AS order_value,
  o.freight_revenue                          AS freight_value,
  SAFE_DIVIDE(o.freight_revenue, o.items_revenue) AS freight_ratio,
  o.items_count,
  o.sellers_count,
  o.primary_payment_type                     AS payment_type,
  o.max_installments,
  p.weight_g,
  p.volume_cm3,
  p.photos_qty,
  p.description_length,
  EXTRACT(DAYOFWEEK FROM o.purchased_at)     AS purchase_dow,
  EXTRACT(HOUR FROM o.purchased_at)          AS purchase_hour,
  TIMESTAMP_DIFF(o.estimated_delivery_at, o.purchased_at, DAY) AS promised_delivery_days,
  ROUND(TIMESTAMP_DIFF(o.approved_at, o.purchased_at, HOUR), 1)  AS approval_hours,
  ROUND(TIMESTAMP_DIFF(o.shipped_at, o.purchased_at, HOUR) / 24, 2) AS days_to_ship,
  o.delivery_days,
  o.delivery_delay_days,
  CAST(o.is_late AS INT64)                   AS is_late
FROM `{{project}}.{{marts}}.fct_orders` o
JOIN main_item mi USING (order_id)
LEFT JOIN `{{project}}.{{marts}}.dim_products` p ON p.product_id = mi.m.product_id
LEFT JOIN `{{project}}.{{marts}}.dim_customers` c ON c.customer_unique_id = o.customer_unique_id
LEFT JOIN `{{project}}.{{marts}}.dim_sellers` s ON s.seller_id = mi.m.seller_id
WHERE o.order_status = 'delivered'
  AND o.delivered_at IS NOT NULL
  AND o.review_score IS NOT NULL
  AND o.purchase_date >= '2017-01-01'
  AND o.purchase_date <  '2018-09-01';
