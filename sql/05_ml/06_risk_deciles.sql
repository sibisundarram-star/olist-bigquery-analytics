WITH scored AS (
  SELECT t.is_bad_review, pr.prob
  FROM ML.PREDICT(
         MODEL `{{project}}.{{marts}}.bad_review_with_fulfillment`,
         (SELECT * FROM `{{project}}.{{marts}}.ml_review_features` WHERE split = 'test')) t,
       UNNEST(t.predicted_is_bad_review_probs) pr
  WHERE pr.label = 1
),
ranked AS (
  SELECT *, NTILE(10) OVER (ORDER BY prob DESC) AS risk_decile FROM scored
)
SELECT
  risk_decile,
  COUNT(*)                                       AS orders,
  ROUND(100 * AVG(is_bad_review), 1)             AS bad_review_rate_pct,
  ROUND(SAFE_DIVIDE(AVG(is_bad_review), (SELECT AVG(is_bad_review) FROM scored)), 2) AS lift,
  ROUND(100 * SUM(SUM(is_bad_review)) OVER (ORDER BY risk_decile)
            / SUM(SUM(is_bad_review)) OVER (), 1) AS cumulative_pct_of_bad_reviews
FROM ranked
GROUP BY risk_decile
ORDER BY risk_decile;
