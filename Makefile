# Usage: make all SOURCE=path/to/archive.zip   (or a folder of the CSVs)
SOURCE ?= data

.PHONY: setup load staging marts tests analysis all

setup:
	pip install -r requirements.txt

load:
	python scripts/load_raw.py --source $(SOURCE)

staging:
	python scripts/run_sql.py sql/01_staging

marts:
	python scripts/run_sql.py sql/02_marts

tests:
	python scripts/run_sql.py sql/03_tests --expect-empty

analysis:
	python scripts/run_sql.py sql/04_analysis --show 15

all: load staging marts tests
