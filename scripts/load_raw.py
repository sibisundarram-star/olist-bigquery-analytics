"""Load the 9 Olist CSVs into BigQuery (dataset: olist_raw).

    python scripts/load_raw.py --source archive.zip
    python scripts/load_raw.py --source ./data
"""
import argparse
import tempfile
import zipfile
from pathlib import Path

from google.cloud import bigquery
from common import Config, get_client

F = bigquery.SchemaField
S, I, N, T = "STRING", "INT64", "FLOAT64", "TIMESTAMP"

# table name -> (csv file, schema). Raw keeps the source column names (typos included);
# renaming/cleaning happens in the staging layer.
TABLES = {
    "customers": ("olist_customers_dataset.csv", [
        F("customer_id", S), F("customer_unique_id", S),
        F("customer_zip_code_prefix", I), F("customer_city", S), F("customer_state", S)]),
    "geolocation": ("olist_geolocation_dataset.csv", [
        F("geolocation_zip_code_prefix", I), F("geolocation_lat", N),
        F("geolocation_lng", N), F("geolocation_city", S), F("geolocation_state", S)]),
    "order_items": ("olist_order_items_dataset.csv", [
        F("order_id", S), F("order_item_id", I), F("product_id", S), F("seller_id", S),
        F("shipping_limit_date", T), F("price", N), F("freight_value", N)]),
    "order_payments": ("olist_order_payments_dataset.csv", [
        F("order_id", S), F("payment_sequential", I), F("payment_type", S),
        F("payment_installments", I), F("payment_value", N)]),
    "order_reviews": ("olist_order_reviews_dataset.csv", [
        F("review_id", S), F("order_id", S), F("review_score", I),
        F("review_comment_title", S), F("review_comment_message", S),
        F("review_creation_date", T), F("review_answer_timestamp", T)]),
    "orders": ("olist_orders_dataset.csv", [
        F("order_id", S), F("customer_id", S), F("order_status", S),
        F("order_purchase_timestamp", T), F("order_approved_at", T),
        F("order_delivered_carrier_date", T), F("order_delivered_customer_date", T),
        F("order_estimated_delivery_date", T)]),
    "products": ("olist_products_dataset.csv", [
        F("product_id", S), F("product_category_name", S),
        F("product_name_lenght", I), F("product_description_lenght", I),
        F("product_photos_qty", I), F("product_weight_g", I), F("product_length_cm", I),
        F("product_height_cm", I), F("product_width_cm", I)]),
    "sellers": ("olist_sellers_dataset.csv", [
        F("seller_id", S), F("seller_zip_code_prefix", I), F("seller_city", S),
        F("seller_state", S)]),
    "category_translation": ("product_category_name_translation.csv", [
        F("product_category_name", S), F("product_category_name_english", S)]),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", required=True, help="Folder of CSVs or the .zip archive")
    args = ap.parse_args()

    src = Path(args.source)
    tmp = None
    if src.suffix == ".zip":
        tmp = tempfile.TemporaryDirectory()
        with zipfile.ZipFile(src) as z:
            z.extractall(tmp.name)
        src = Path(tmp.name)

    client = get_client()
    for ds in (Config.raw, Config.staging, Config.marts):
        dataset = bigquery.Dataset(f"{Config.project}.{ds}")
        dataset.location = Config.location
        client.create_dataset(dataset, exists_ok=True)
        print(f"dataset ready: {ds}")

    for table, (filename, schema) in TABLES.items():
        path = src / filename
        if not path.exists():
            raise SystemExit(f"Missing {path}")
        cfg = bigquery.LoadJobConfig(
            schema=schema,
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            allow_quoted_newlines=True,  # review comments contain line breaks
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        )
        with open(path, "rb") as fh:
            job = client.load_table_from_file(
                fh, f"{Config.project}.{Config.raw}.{table}", job_config=cfg)
        job.result()
        print(f"loaded {Config.raw}.{table:<22} {job.output_rows:>9,} rows")

    if tmp:
        tmp.cleanup()


if __name__ == "__main__":
    main()
