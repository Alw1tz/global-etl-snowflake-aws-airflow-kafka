"""
Snowflake Time Travel.

--------
* DAG Name:
    lab_04_time_travel
* Owner:
    alw1tz
* Description:
    Query historical data using AT/BEFORE syntax.
    Creates a table, captures a timestamp, mutates the data, then travels back
    to the snapshot to verify the original state.
    Also demonstrates CLONE from a past OFFSET — zero-copy table snapshot.
"""
from __future__ import annotations

import os
import time
import pendulum
from airflow import DAG
from airflow.decorators import task

from utils.settings import get_default_args

# -------------------- Globals --------------------
DATABASE = 'LABS_DB'
SCHEMA   = 'LABS'
TABLE    = f'{DATABASE}.{SCHEMA}.ORDERS'

PARAMS       = {'database': DATABASE, 'schema': SCHEMA, 'table': TABLE}
QUERIES_PATH = os.path.join(os.path.dirname(__file__), 'queries')

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_04_time_travel',
    description='Snowflake Time Travel — AT/BEFORE syntax and zero-copy CLONE.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['snowflake', 'lab'],
) as dag:

    @task
    def setup():
        from utils.commons import execute_snowflake, read_query
        execute_snowflake(f"CREATE DATABASE IF NOT EXISTS {DATABASE}")
        execute_snowflake(f"CREATE SCHEMA IF NOT EXISTS {DATABASE}.{SCHEMA}")
        execute_snowflake(read_query(QUERIES_PATH, 'lab_04_create_orders.sql', PARAMS))
        execute_snowflake(read_query(QUERIES_PATH, 'lab_04_insert_orders.sql', PARAMS))

    @task
    def update_and_travel() -> str:
        from utils.commons import execute_snowflake, snowflake_to_pandas
        ts_row      = snowflake_to_pandas("SELECT CURRENT_TIMESTAMP() AS ts")
        snapshot_ts = str(ts_row['TS'].iloc[0])

        time.sleep(5)

        execute_snowflake(f"UPDATE {TABLE} SET status = 'COMPLETED' WHERE id IN (1, 2)")
        execute_snowflake(f"DELETE FROM {TABLE} WHERE id = 3")

        print("=== CURRENT STATE ===")
        print(snowflake_to_pandas(f"SELECT * FROM {TABLE}").to_string(index=False))

        print(f"\n=== TIME TRAVEL — before update (snapshot: {snapshot_ts}) ===")
        df_past = snowflake_to_pandas(
            f"SELECT * FROM {TABLE} BEFORE (TIMESTAMP => '{snapshot_ts}'::TIMESTAMP_LTZ)"
        )
        print(df_past.to_string(index=False))

        return snapshot_ts

    @task
    def clone_from_past(snapshot_ts: str):
        from utils.commons import execute_snowflake, snowflake_to_pandas
        execute_snowflake(f"""
            CREATE OR REPLACE TABLE {DATABASE}.{SCHEMA}.ORDERS_CLONE
            CLONE {TABLE} BEFORE (TIMESTAMP => '{snapshot_ts}'::TIMESTAMP_LTZ)
        """)
        df = snowflake_to_pandas(f"SELECT * FROM {DATABASE}.{SCHEMA}.ORDERS_CLONE")
        print("Cloned table (state before updates):")
        print(df.to_string(index=False))

    # -------------------- Task Dependencies --------------------
    t_setup    = setup()
    t_snapshot = update_and_travel()
    t_setup >> t_snapshot
    clone_from_past(t_snapshot)
