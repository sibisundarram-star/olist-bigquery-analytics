-- Fixes the "lenght" typos, adds English category names, and covers the two
-- categories missing from the translation file plus products with no category.
CREATE OR REPLACE VIEW `{{project}}.{{staging}}.stg_products` AS
SELECT
  p.product_id,
  p.product_category_name AS category_pt,
  CASE
    WHEN p.product_category_name IS NULL THEN 'unknown'
    WHEN p.product_category_name = 'pc_gamer' THEN 'pc_gamer'
    WHEN p.product_category_name = 'portateis_cozinha_e_preparadores_de_alimentos'
      THEN 'portable_kitchen_food_preparers'
    ELSE COALESCE(t.product_category_name_english, p.product_category_name)
  END AS category,
  p.product_name_lenght        AS name_length,
  p.product_description_lenght AS description_length,
  p.product_photos_qty         AS photos_qty,
  p.product_weight_g           AS weight_g,
  p.product_length_cm          AS length_cm,
  p.product_height_cm          AS height_cm,
  p.product_width_cm           AS width_cm,
  p.product_length_cm * p.product_height_cm * p.product_width_cm AS volume_cm3
FROM `{{project}}.{{raw}}.products` p
LEFT JOIN `{{project}}.{{raw}}.category_translation` t
  USING (product_category_name);
