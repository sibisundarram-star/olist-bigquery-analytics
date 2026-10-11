SELECT customer_unique_id, COUNT(*) AS n
FROM `{{project}}.{{marts}}.dim_customers`
GROUP BY customer_unique_id
HAVING n > 1;
