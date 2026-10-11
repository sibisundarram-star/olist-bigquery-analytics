-- order-level and item-level revenue must agree to the cent
SELECT o.total AS orders_total, i.total AS items_total
FROM (SELECT ROUND(SUM(items_revenue), 2) AS total FROM `{{project}}.{{marts}}.fct_orders`) o,
     (SELECT ROUND(SUM(price), 2)         AS total FROM `{{project}}.{{marts}}.fct_order_items`) i
WHERE o.total != i.total;
