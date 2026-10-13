CREATE OR REPLACE MODEL `{{project}}.{{marts}}.bad_review_order_time`
OPTIONS (
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['is_bad_review'],
  max_iterations = 60,
  max_tree_depth = 6,
  learn_rate = 0.1,
  subsample = 0.8,
  early_stop = TRUE
) AS
SELECT
  is_bad_review,
  customer_state, seller_state, same_state, distance_km, category,
  order_value, freight_value, freight_ratio, items_count, sellers_count,
  payment_type, max_installments, weight_g, volume_cm3, photos_qty,
  description_length, purchase_dow, purchase_hour, promised_delivery_days
FROM `{{project}}.{{marts}}.ml_review_features`
WHERE split = 'train';
