# Olist E-Commerce Analytics on BigQuery

An ELT project on the [Olist Brazilian e-commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(~100k orders, 2016-2018): raw load → cleaned staging views → star-schema marts → data tests → analysis queries.
The whole dataset is ~126 MB, so it fits comfortably in BigQuery's free tier.

## Architecture

```
CSV (9 files)
   │  scripts/load_raw.py        explicit schemas, WRITE_TRUNCATE
   ▼
olist_raw         9 tables, source column names untouched
   │  sql/01_staging             views: rename, type, dedupe, translate categories
   ▼
olist_staging     stg_orders, stg_customers, stg_sellers, stg_products,
   │              stg_order_items, stg_payments, stg_reviews, stg_geolocation
   │  sql/02_marts               tables: partitioned + clustered
   ▼
olist_marts       dim_date, dim_customers, dim_sellers, dim_products
                  fct_orders, fct_order_items
                  mart_monthly_kpis, mart_customer_rfm, mart_seller_scorecard
   │  sql/03_tests               each query must return 0 rows
   │  sql/04_analysis            8 business questions
```

## Quick start

```bash
pip install -r requirements.txt
gcloud auth application-default login

export GCP_PROJECT=your-project-id      # optional: BQ_LOCATION (default US)
make all SOURCE=path/to/archive.zip     # load -> staging -> marts -> tests
make analysis                           # runs the 8 analysis queries, prints top rows
```

`SOURCE` can be the zip or a folder with the extracted CSVs. Each step is also runnable alone
(`make load`, `make staging`, `make marts`, `make tests`). SQL files use `{{project}}`, `{{raw}}`,
`{{staging}}`, `{{marts}}` placeholders, so dataset names are configurable via `.env.example`.

## Data quirks handled (and where)

| Quirk in source data | Handling |
|---|---|
| `customer_id` changes per order; `customer_unique_id` is the real customer (99,441 ids → 96,096 people) | `dim_customers` is keyed on `customer_unique_id`; all retention/RFM work uses it |
| `review_id` not unique; some orders have several reviews | `stg_reviews` keeps the latest review per order |
| Review comments contain line breaks | loader sets `allow_quoted_newlines` |
| `geolocation` has 1M rows for 19k zip prefixes | `stg_geolocation` collapses to one centroid per prefix |
| Two categories missing from the translation table, 610 products with no category | explicit mapping / `unknown` in `stg_products` |
| Column typos (`product_name_lenght`) | renamed in staging |
| 775 orders have no items (mostly canceled/unavailable) | kept in `fct_orders` with zero revenue; `is_valid_order` flag excludes canceled/unavailable from KPIs |
| 2016 is sparse; Sep/Oct 2018 incomplete | trend queries start in 2017-01 and stop at 2018-08 |

## Design choices

- **Staging as views, marts as tables**: staging costs nothing to store and always reflects raw; marts are
  materialized for fast, cheap dashboard queries.
- **Cluster** the fact tables by `purchase_date` plus common filters. Partitioning was dropped because the BigQuery Sandbox expires partitions after 60 days, which silently emptied the tables.
- **Tests as SQL**: the runner treats any returned row as a failure, so you can drop new `.sql` files into
  `sql/03_tests` with no code changes.

## Sanity checks after loading

| Check | Expected |
|---|---|
| `olist_raw.orders` rows | 99,441 |
| `olist_raw.order_items` rows | 112,650 |
| `SUM(price)` in `fct_order_items` | 13,591,643.70 |
| `dim_customers` rows | 96,096 |
| `make tests` | 7 × PASS |

## Ideas for extending it

- Connect Looker Studio to `olist_marts` for a dashboard (monthly KPIs, state map via `lat`/`lng`, seller scorecard).
- BigQuery ML: predict low review scores (`review_score <= 2`) from delivery delay, freight ratio, category and
  seller state using `CREATE MODEL ... OPTIONS(model_type='logistic_reg')`.
- Sentiment/topic analysis of the Portuguese review comments with `ML.GENERATE_TEXT` or `AI.GENERATE`.
- Scheduled queries or Dataform/dbt to run the layers on a schedule.

## Machine learning: predicting bad reviews

BigQuery ML boosted-tree models predict which orders get a 1-2 star review (time-based train/test split).
Purchase-time features alone are weak (AUC 0.63); adding delivery outcomes lifts AUC to 0.75, and the
top-risk 10% of orders hold 43% of all bad reviews. Details and limitations in [docs/ML.md](docs/ML.md);
SQL in `sql/05_ml/`.
