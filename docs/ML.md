# Predicting bad reviews with BigQuery ML

**Question:** can we predict which orders get a 1-2 star review, and how much does delivery performance explain?

## Setup
- Population: delivered, reviewed orders, Jan 2017 - Aug 2018 (~95.5k orders, ~12.8% bad reviews).
- Label: `is_bad_review` = review score <= 2.
- Time-based split: train before 2018-03-01, test from 2018-03 onward (12.3% bad reviews in test).
- Algorithm: BigQuery ML `BOOSTED_TREE_CLASSIFIER`, same hyperparameters for both models, threshold 0.25.

## Results (held-out test set)
| Model | ROC AUC | Precision | Recall | F1 |
|---|---|---|---|---|
| A: order-time features only | 0.626 | 28.8% | 19.3% | 0.231 |
| B: + fulfillment features | 0.754 | 50.8% | 45.0% | 0.477 |

Accuracy is not informative here: always predicting "good review" scores about 87.7%.

## Takeaways
- Purchase-time information is a weak predictor. The strongest signals are `items_count` and `sellers_count` (multi-item / multi-seller orders are riskier; hypothesis: split shipments or missing items, untested).
- Delivery performance is the dominant signal: `delivery_delay_days` is Model B's top feature, and adding fulfillment features lifts AUC from 0.63 to 0.75 and roughly doubles precision and recall.
- Ranking orders by Model B risk: the top decile has a 53.4% bad-review rate (4.3x lift) and contains 43% of all bad reviews; the top two deciles contain 57%.

## Limitations
- Observational data: predictive does not mean causal.
- Model B uses information only available after delivery, so it is a diagnostic / service-recovery tool, not a purchase-time predictor.
- The test period has a higher late-delivery rate than training, which is realistic drift but lowers scores.
- Review text is not used (Portuguese NLP is a natural next step).

Raw output: `docs/ml_results.txt`. Reproduce with `python scripts/run_sql.py sql/05_ml`.
