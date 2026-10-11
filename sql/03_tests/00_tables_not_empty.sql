SELECT tbl, n FROM (
  SELECT 'fct_orders' AS tbl, COUNT(*) AS n FROM `{{project}}.{{marts}}.fct_orders`
  UNION ALL SELECT 'fct_order_items', COUNT(*) FROM `{{project}}.{{marts}}.fct_order_items`
  UNION ALL SELECT 'dim_customers', COUNT(*) FROM `{{project}}.{{marts}}.dim_customers`
  UNION ALL SELECT 'mart_monthly_kpis', COUNT(*) FROM `{{project}}.{{marts}}.mart_monthly_kpis`
  UNION ALL SELECT 'mart_customer_rfm', COUNT(*) FROM `{{project}}.{{marts}}.mart_customer_rfm`
  UNION ALL SELECT 'mart_seller_scorecard', COUNT(*) FROM `{{project}}.{{marts}}.mart_seller_scorecard`
)
WHERE n = 0;
