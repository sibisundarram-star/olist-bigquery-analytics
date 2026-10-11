"""Shared config + SQL templating for the Olist BigQuery project."""
import os
from google.cloud import bigquery


class Config:
    project = os.environ.get("GCP_PROJECT") or os.environ.get("GOOGLE_CLOUD_PROJECT")
    location = os.environ.get("BQ_LOCATION", "US")
    raw = os.environ.get("BQ_RAW_DATASET", "olist_raw")
    staging = os.environ.get("BQ_STAGING_DATASET", "olist_staging")
    marts = os.environ.get("BQ_MARTS_DATASET", "olist_marts")


def get_client() -> bigquery.Client:
    if not Config.project:
        raise SystemExit("Set GCP_PROJECT (see .env.example).")
    return bigquery.Client(project=Config.project, location=Config.location)


def render(sql: str) -> str:
    """Replace {{project}}, {{raw}}, {{staging}}, {{marts}} placeholders."""
    for key in ("project", "raw", "staging", "marts"):
        sql = sql.replace("{{" + key + "}}", getattr(Config, key))
    return sql
