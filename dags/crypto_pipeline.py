from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime
from scripts.ingest import fetch_and_load_api

with DAG(
    dag_id='crypto_clickhouse_pipeline', 
    start_date=datetime(2026, 1, 1), 
    schedule_interval='@daily', 
    catchup=False
) as dag:

    ingest_task = PythonOperator(
        task_id='fetch_api_and_load_to_clickhouse',
        python_callable=fetch_and_load_api
    )

    dbt_run = BashOperator(
        task_id='dbt_run',
        bash_command='cd /opt/airflow/dbt_project && dbt run --target dev'
    )

    ingest_task >> dbt_run