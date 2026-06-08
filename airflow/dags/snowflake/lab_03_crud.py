"""
Snowflake CRUD operations.

--------
* DAG Name:
    lab_03_crud
* Owner:
    alw1tz
* Description:
    Full CRUD lifecycle on a Snowflake table: CREATE / INSERT / SELECT / UPDATE / DELETE.
    Each step is an isolated task; the final verify task shows the resulting state.
"""
from __future__ import annotations

import os
import pendulum
from airflow import DAG
from airflow.decorators import task

from utils.settings import get_default_args

# -------------------- Globals --------------------
DATABASE = 'LABS_DB'
SCHEMA   = 'LABS'
TABLE    = f'{DATABASE}.{SCHEMA}.USERS'

PARAMS       = {'database': DATABASE, 'schema': SCHEMA, 'table': TABLE}
QUERIES_PATH = os.path.join(os.path.dirname(__file__), 'queries')

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_03_crud',
    description='CREATE / INSERT / SELECT / UPDATE / DELETE on Snowflake.',
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
        execute_snowflake(read_query(QUERIES_PATH, 'lab_03_create_users.sql', PARAMS))
        print(f"Table {TABLE} ready.")

    @task
    def insert():
        from utils.commons import execute_snowflake, read_query
        execute_snowflake(read_query(QUERIES_PATH, 'lab_03_insert_users.sql', PARAMS))

    @task
    def read():
        from utils.commons import snowflake_to_pandas
        df = snowflake_to_pandas(f"SELECT * FROM {TABLE} ORDER BY id")
        print(df.to_string(index=False))

    @task
    def update():
        from utils.commons import execute_snowflake, read_query
        execute_snowflake(read_query(QUERIES_PATH, 'lab_03_update_email.sql', PARAMS))

    @task
    def delete():
        from utils.commons import execute_snowflake, read_query
        execute_snowflake(read_query(QUERIES_PATH, 'lab_03_delete_user.sql', PARAMS))

    @task
    def verify():
        from utils.commons import snowflake_to_pandas
        df = snowflake_to_pandas(f"SELECT * FROM {TABLE} ORDER BY id")
        print("Final state:")
        print(df.to_string(index=False))

    # -------------------- Task Dependencies --------------------
    setup() >> insert() >> read() >> update() >> delete() >> verify()
