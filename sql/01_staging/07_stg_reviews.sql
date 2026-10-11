-- review_id is NOT unique in the source and some orders have several reviews.
-- Keep exactly one review per order: the most recently answered.
CREATE OR REPLACE VIEW `{{project}}.{{staging}}.stg_reviews` AS
SELECT
  review_id,
  order_id,
  review_score,
  review_comment_title   AS comment_title,
  review_comment_message AS comment_message,
  review_creation_date   AS created_at,
  review_answer_timestamp AS answered_at
FROM `{{project}}.{{raw}}.order_reviews`
WHERE TRUE
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY order_id
  ORDER BY review_answer_timestamp DESC, review_id
) = 1;
