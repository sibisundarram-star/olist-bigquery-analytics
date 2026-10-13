# Olist E-Commerce Analytics on BigQuery

End-to-end analytics project on the [Olist Brazilian e-commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(~100k orders, 2016-2018): raw load, cleaned staging, a star-schema warehouse, automated data tests,
business analysis in SQL, and BigQuery ML models that predict bad reviews.

**Stack:** BigQuery (SQL, BigQuery ML), Python, Make. Built and run in Google Cloud Shell on the free BigQuery Sandbox.

## Key findings

1. **Late delivery is the strongest driver of bad reviews.** Orders delivered on time or early average 4.29 stars
   (9.2% bad reviews, i.e. 1-2 stars). Orders 3-6 days late average 2.32 stars (61.3% bad); 7+ days late average 1.73 stars (78.4% bad).
2. **Delivery quality worsened during growth.** Monthly revenue grew from about R$120k (Jan 2017) to about R$1.0M (Nov 2017),
   while the late-delivery rate rose from about 3% to 14.3% in Nov 2017 and 21.4% by Mar 2018; average review score fell from 4.09 to 3.76.
3. **Customers rarely come back.** About 3% of customers ever order twice, and only about 0.3-0.4% of an acquisition cohort orders again the following month.
4. **Revenue is concentrated, and some regions are underserved.** SP, RJ and MG make up about 63% of revenue. RJ is the second-largest state but has a
   13.5% late rate (MG: 5.6%). In MA, freight is 26.3% of item value, delivery takes 21.6 days on average and 19.7% of orders are late.
5. **The win-back opportunity is in "at risk" high-value customers.** They are 14.7% of customers but 28.9% of revenue, with about 445 days since their last order.
   43.5% of customers are dormant.

## Machine learning: predicting bad reviews

BigQuery ML boosted-tree classifiers, trained on orders before 2018-03-01 and tested on later orders (time-based split, 12.3% bad reviews in test).

| Model | ROC AUC | Precision | Recall |
|---|---|---|---|
| A: features known at purchase | 0.626 | 28.8% | 19.3% |
| B: + fulfillment / delivery outcome | 0.754 | 50.8% | 45.0% |

- Purchase-time information is a weak predictor; the top signals are the number of items and sellers in the order.
- Delivery delay vs. the promised date is Model B's top feature, and adding it roughly doubles precision and recall.
- Ranking orders by Model B risk, the top 10% have a 53.4

cd ~/olist-bigquery
cat > README.md <<'EOF'
# Olist E-Commerce Analytics on BigQuery

End-to-end analytics project on the [Olist Brazilian e-commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(~100k orders, 2016-2018): raw load, cleaned staging, a star-schema warehouse, automated data tests,
business analysis in SQL, and BigQuery ML models that predict bad reviews.

**Stack:** BigQuery (SQL, BigQuery ML), Python, Make. Built and run in Google Cloud Shell on the free BigQuery Sandbox.

## Key findings

1. **Late delivery is the strongest driver of bad reviews.** Orders delivered on time or early average 4.29 stars
   (9.2% bad reviews, i.e. 1-2 stars). Orders 3-6 days late average 2.32 stars (61.3% bad); 7+ days late average 1.73 stars (78.4% bad).
2. **Delivery quality worsened during growth.** Monthly revenue grew from about R$120k (Jan 2017) to about R$1.0M (Nov 2017),
   while the late-delivery rate rose from about 3% to 14.3% in Nov 2017 and 21.4% by Mar 2018; average review score fell from 4.09 to 3.76.
3. **Customers rarely come back.** About 3% of customers ever order twice, and only about 0.3-0.4% of an acquisition cohort orders again the following month.
4. **Revenue is concentrated, and some regions are underserved.** SP, RJ and MG make up about 63% of revenue. RJ is the second-largest state but has a
   13.5% late rate (MG: 5.6%). In MA, freight is 26.3% of item value, delivery takes 21.6 days on average and 19.7% of orders are late.
5. **The win-back opportunity is in "at risk" high-value customers.** They are 14.7% of customers but 28.9% of revenue, with about 445 days since their last order.
   43.5% of customers are dormant.

## Machine learning: predicting bad reviews

BigQuery ML boosted-tree classifiers, trained on orders before 2018-03-01 and tested on later orders (time-based split, 12.3% bad reviews in test).

| Model | ROC AUC | Precision | Recall |
|---|---|---|---|
| A: features known at purchase | 0.626 | 28.8% | 19.3% |
| B: + fulfillment / delivery outcome | 0.754 | 50.8% | 45.0% |

- Purchase-time information is a weak predictor; the top signals are the number of items and sellers in the order.
- Delivery delay vs. the promised date is Model B's top feature, and adding it roughly doubles precision and recall.
- Ranking orders by Model B risk, the top 10% have a 53.4% bad-review rate (4.3x lift) and contain 43% of all bad reviews.

Details, caveats and reproduction steps: [docs/ML.md](docs/ML.md).

## Architecture

~~~
CSV (9 files)
   |  scripts/load_raw.py        explicit schemas, WRITE_TRUNCATE
   v
olist_raw         9 tables, source column names untouched
   |  sql/01_staging             views: rename, type, dedupe, translate categories
   v
olist_staging     8 views
   |  sql/02_marts               tables: dimensions, facts, aggregate marts
   v
olist_marts       dim_date, dim_customers, dim_sellers, dim_products,
                  fct_orders, fct_order_items,
                  mart_monthly_kpis, mart_customer_rfm, mart_seller_scorecard,
                  ml_review_features + 2 BigQuery ML models
   |  sql/03_tests              7 checks, each must return 0 rows
   |  sql/04_analysis           8 business questions
   |  sql/05_ml                 features, training, evaluation, risk deciles
~~~

## Quick start

~~~
pip install -r requirements.txt
gcloud auth application-default login
export GCP_PROJECT=your-project-id
make all SOURCE=path/to/archive.zip     # load, staging, marts, tests
make analysis                           # prints the 8 analysis queries
python scripts/run_sql.py sql/05_ml     # trains and evaluates the ML models
~~~

`SOURCE` can be the downloaded zip or a folder of the extracted CSVs. SQL files use `{{project}}`, `{{raw}}`,
`{{staging}}` and `{{marts}}` placeholders, so dataset names are configurable (see `.env.example`).
The ML step scans a lot of data during training (tens of GB billed); it is free within BigQuery's monthly quota, but avoid retraining repeatedly.

## Data quirks handled

| Quirk in the source data | Handling |
|---|---|
| `customer_id` changes per order; `customer_unique_id` is the real customer (99,441 ids, 96,096 people) | `dim_customers` is keyed on `customer_unique_id`; retention and RFM use it |
| `review_id` is not unique; some orders have several reviews | `stg_reviews` keeps the latest review per order |
| Review comments contain line breaks | loader sets `allow_quoted_newlines` |
| `geolocation` has 1M rows for 19k zip prefixes | collapsed to one centroid per prefix |
| Two categories missing from the translation table; 610 products with no category | explicit mapping / `unknown` |
| Column typos (`product_name_lenght`) | renamed in staging |
| 775 orders have no items | kept with zero revenue; `is_valid_order` excludes canceled/unavailable from KPIs |
| 2016 is sparse; Sep/Oct 2018 incomplete | trend queries cover 2017-01 to 2018-08 |

## Design notes

- **Staging as views, marts as tables:** staging costs nothing to store and always reflects raw; marts are materialized for fast queries.
- **Clustering instead of partitioning:** the BigQuery Sandbox expires partitions after 60 days, and this data is from 2016-2018. My first version partitioned the
  fact tables by date, so every partition was dropped on write and the tables came out empty, while the data-quality tests still passed because they only looked for
  bad rows. The fix was to cluster by `purchase_date` and add a `00_tables_not_empty` test, so an empty table now fails loudly.
- **Tests as SQL:** any returned row is a failure, so new checks are just new `.sql` files in `sql/03_tests`.

## Limitations

- Observational data: late delivery is strongly associated with bad reviews, but this project does not prove causation.
- Model B uses information only available after delivery, so it is a diagnostic / service-recovery tool, not a purchase-time predictor.
- The test period has a higher late-delivery rate than the training period (realistic drift, but it lowers scores).
- Review text is not used yet. RFM segments are rule-based rather than statistical.
- Sandbox tables and models expire after 60 days; the full pipeline reruns in a few minutes.

## Data

The dataset is not included in this repository. Download it from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce);
it is published under CC BY-NC-SA 4.0.
