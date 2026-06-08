"""
Snowflake connection test and basic queries.

--------
* DAG Name:
    lab_02_connect_query
* Owner:
    alw1tz
* Description:
    Verifies the Snowflake connection using SnowflakeHook and runs basic SELECTs.
    Confirms credentials, warehouse, and sample data are reachable.
"""
from __future__ import annotations

import os
import pendulum
from airflow import DAG
from airflow.decorators import task
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

from utils.settings import get_default_args, SNOWFLAKE_CONN_ID

# -------------------- Globals --------------------
QUERIES_PATH = os.path.join(os.path.dirname(__file__), 'queries')

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_02_connect_query',
    description='Verify Snowflake connection and run basic SELECTs.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['snowflake', 'lab'],
) as dag:

    @task
    def check_connection():
        hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
        row  = hook.get_first(
            "SELECT CURRENT_TIMESTAMP(), CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE()"
        )
        print(f"Timestamp : {row[0]}")
        print(f"User      : {row[1]}")
        print(f"Role      : {row[2]}")
        print(f"Warehouse : {row[3]}")

    @task
    def query_sample_data():
        from utils.commons import snowflake_to_pandas, read_query
        df = snowflake_to_pandas(read_query(QUERIES_PATH, 'lab_02_sample_data.sql'))
        print(df.to_string(index=False))

    @task
    def show_databases():
        from utils.commons import execute_snowflake
        rows = execute_snowflake("SHOW DATABASES")
        for row in rows:
            print(row[1])

    # -------------------- Task Dependencies --------------------
    check_connection() >> query_sample_data() >> show_databases()
