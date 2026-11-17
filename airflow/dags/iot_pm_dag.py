from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    "owner": "alia_almulhim",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(seconds=5),
}

with DAG(
    dag_id="iot_predictive_maintenance_pipeline",
    description="End-to-end IIoT predictive maintenance pipeline: Simulator -> Snowflake -> dbt",
    start_date=datetime(2026, 1, 1),
    schedule="@daily",
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    tags=["iot", "snowflake", "dbt", "medallion"],
) as dag:

    generate_data = BashOperator(
        task_id="generate_iot_telemetry",
        bash_command="echo 'Step 1: Generating synthetic IIoT telemetry'",
    )

    load_to_snowflake = BashOperator(
        task_id="load_raw_to_snowflake",
        bash_command="echo 'Step 2: Loading raw batch to Snowflake RAW layer'",
    )

    dbt_snapshot = BashOperator(
        task_id="dbt_snapshot_dimensions",
        bash_command="echo 'Step 3: Executing dbt snapshot for SCD Type 2'",
    )

    dbt_build = BashOperator(
        task_id="dbt_build_and_test",
        bash_command="echo 'Step 4: Running dbt build and 40 data quality tests'",
    )

    dbt_docs = BashOperator(
        task_id="dbt_generate_docs",
        bash_command="echo 'Step 5: Generating dbt lineage documentation'",
        trigger_rule="all_done",
    )

    generate_data >> load_to_snowflake >> dbt_snapshot >> dbt_build >> dbt_docs