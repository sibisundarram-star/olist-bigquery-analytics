-- every order item must belong to an order
SELECT oi.order_id
FROM `{{project}}.{{staging}}.stg_order_items` oi
LEFT JOIN `{{project}}.{{staging}}.stg_orders` o USING (order_id)
WHERE o.order_id IS NULL;
