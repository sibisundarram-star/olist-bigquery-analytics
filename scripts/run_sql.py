"""Run .sql files (sorted by name) against BigQuery.

    python scripts/run_sql.py sql/01_staging
    python scripts/run_sql.py sql/03_tests --expect-empty   # test files must return 0 rows
    python scripts/run_sql.py sql/04_analysis --show 15     # print first 15 rows of each SELECT
"""
import argparse
import sys
from pathlib import Path

from common import get_client, render


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="+")
    ap.add_argument("--show", type=int, default=0)
    ap.add_argument("--expect-empty", action="store_true")
    args = ap.parse_args()

    files = []
    for p in map(Path, args.paths):
        files += sorted(p.glob("*.sql")) if p.is_dir() else [p]

    client = get_client()
    failures = 0
    for f in files:
        job = client.query(render(f.read_text()))
        rows = list(job.result())
        gb = (job.total_bytes_billed or 0) / 1e9
        if args.expect_empty:
            if rows:
                failures += 1
                print(f"FAIL  {f.name}: {len(rows)} offending rows, e.g. {dict(rows[0])}")
            else:
                print(f"PASS  {f.name}")
        else:
            print(f"OK    {f.name}  ({gb:.3f} GB billed)")
            if args.show and job.statement_type == "SELECT":
                for r in rows[: args.show]:
                    print("      ", dict(r))
    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
