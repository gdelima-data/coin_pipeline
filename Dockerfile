FROM apache/airflow:2.7.1-python3.10

RUN pip install --no-cache-dir clickhouse-driver dbt-clickhouse