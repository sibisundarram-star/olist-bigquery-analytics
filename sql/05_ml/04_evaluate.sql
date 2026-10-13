SELECT 'A: order-time only' AS model, *
FROM ML.EVALUATE(
  MODEL `{{project}}.{{marts}}.bad_review_order_time`,
  (SELECT * FROM `{{project}}.{{marts}}.ml_review_features` WHERE split = 'test'),
  STRUCT(0.25 AS threshold))
UNION ALL
SELECT 'B: + fulfillment' AS model, *
FROM ML.EVALUATE(
  MODEL `{{project}}.{{marts}}.bad_review_with_fulfillment`,
  (SELECT * FROM `{{project}}.{{marts}}.ml_review_features` WHERE split = 'test'),
  STRUCT(0.25 AS threshold));
