"""
Snowflake Streams — CDC pattern.

--------
* DAG Name:
    lab_05_streams
* Owner:
    alw1tz
* Description:
    Capture INSERT/UPDATE/DELETE changes via a Snowflake Stream.
    Demonstrates the CDC pattern: source table → stream → sink table.
    Consuming the stream (INSERT INTO sink FROM stream) clears it,
    enabling idempotent incremental loads.
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
SOURCE   = f'{DATABASE}.{SCHEMA}.EVENTS'
STREAM   = f'{DATABASE}.{SCHEMA}.EVENTS_STREAM'
SINK     = f'{DATABASE}.{SCHEMA}.EVENTS_PROCESSED'

PARAMS       = {'database': DATABASE, 'schema': SCHEMA, 'source': SOURCE, 'stream': STREAM, 'sink': SINK}
QUERIES_PATH = os.path.join(os.path.dirname(__file__), 'queries')

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_05_streams',
    description='CDC pattern with Snowflake Streams — source → stream → sink.',
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
        execute_snowflake(read_query(QUERIES_PATH, 'lab_05_create_events.sql', PARAMS))
        execute_snowflake(read_query(QUERIES_PATH, 'lab_05_create_events_processed.sql', PARAMS))
        execute_snowflake(f"CREATE OR REPLACE STREAM {STREAM} ON TABLE {SOURCE}")
        print("Stream created on EVENTS table.")

    @task
    def insert_events():
        from utils.commons import execute_snowflake, read_query
        execute_snowflake(read_query(QUERIES_PATH, 'lab_05_insert_events.sql', PARAMS))

    @task
    def read_stream():
        from utils.commons import snowflake_to_pandas
        df = snowflake_to_pandas(f"SELECT * FROM {STREAM}")
        print(f"Changes captured in stream: {len(df)} rows")
        print(df[['ID', 'EVENT_TYPE', 'METADATA$ACTION', 'METADATA$ISUPDATE']].to_string(index=False))

    @task
    def consume_stream():
        from utils.commons import execute_snowflake, snowflake_to_pandas, read_query
        execute_snowflake(read_query(QUERIES_PATH, 'lab_05_consume_stream.sql', PARAMS))
        remaining = snowflake_to_pandas(f"SELECT COUNT(*) AS cnt FROM {STREAM}")
        print(f"Rows remaining in stream after consume: {remaining['CNT'].iloc[0]}")
        df = snowflake_to_pandas(f"SELECT * FROM {SINK}")
        print("Processed events:")
        print(df.to_string(index=False))

    # -------------------- Task Dependencies --------------------
    setup() >> insert_events() >> read_stream() >> consume_stream()
