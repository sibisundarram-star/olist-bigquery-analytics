SELECT order_id, review_score
FROM `{{project}}.{{marts}}.fct_orders`
WHERE review_score IS NOT NULL AND review_score NOT BETWEEN 1 AND 5;
