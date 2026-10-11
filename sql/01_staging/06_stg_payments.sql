CREATE OR REPLACE VIEW `{{project}}.{{staging}}.stg_payments` AS
SELECT
  order_id,
  payment_sequential,
  payment_type,
  payment_installments AS installments,
  payment_value
FROM `{{project}}.{{raw}}.order_payments`;
