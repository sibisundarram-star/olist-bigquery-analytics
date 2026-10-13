SELECT 'A: order-time only' AS model, feature, ROUND(importance_gain, 1) AS importance_gain
FROM ML.FEATURE_IMPORTANCE(MODEL `{{project}}.{{marts}}.bad_review_order_time`)
UNION ALL
SELECT 'B: + fulfillment', feature, ROUND(importance_gain, 1)
FROM ML.FEATURE_IMPORTANCE(MODEL `{{project}}.{{marts}}.bad_review_with_fulfillment`)
ORDER BY model, importance_gain DESC;
