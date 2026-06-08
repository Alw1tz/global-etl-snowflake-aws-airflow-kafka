"""
Full pipeline — generate data → S3 → Snowflake → validate.

--------
* DAG Name:
    lab_11_full_pipeline
* Owner:
    alw1tz
* Description:
    End-to-end pipeline that ties together all previous labs:
      1. Generate synthetic transaction data and upload to S3
      2. Create the target table in Snowflake
      3. COPY INTO from S3 to Snowflake
      4. Validate the row count matches expectations
    Demonstrates the standard pattern used in production data pipelines.
"""
from __future__ import annotations

import os
import pendulum
from airflow import DAG
from airflow.decorators import task

from utils.settings import get_default_args, S3_BUCKET

# -------------------- Globals --------------------
DATABASE = 'LABS_DB'
SCHEMA   = 'LABS'
TABLE    = f'{DATABASE}.{SCHEMA}.PIPELINE_TRANSACTIONS'
KEY      = 'pipeline/transactions.csv'

PARAMS       = {'database': DATABASE, 'schema': SCHEMA, 'table': TABLE, 'bucket': S3_BUCKET, 'key': KEY}
QUERIES_PATH = os.path.join(os.path.dirname(__file__), 'queries')

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_11_full_pipeline',
    description='Full pipeline: generate data → S3 → COPY INTO Snowflake → validate.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['integration', 'lab'],
) as dag:

    @task
    def generate_and_upload():
        from utils.commons import get_s3_client, upload_to_s3
        s3 = get_s3_client()
        try:
            s3.create_bucket(Bucket=S3_BUCKET)
        except Exception:
            pass
        rows = ['id,user_name,amount,currency,status']
        data = [
            (1,  'alice',  150.00, 'USD', 'COMPLETED'),
            (2,  'bob',     89.99, 'USD', 'PENDING'),
            (3,  'carlos', 320.50, 'MXN', 'COMPLETED'),
            (4,  'diana',   45.00, 'USD', 'FAILED'),
            (5,  'eve',    200.00, 'USD', 'COMPLETED'),
            (6,  'frank',  500.00, 'MXN', 'COMPLETED'),
            (7,  'grace',   12.50, 'USD', 'PENDING'),
            (8,  'henry',  999.99, 'USD', 'COMPLETED'),
            (9,  'iris',    77.00, 'MXN', 'COMPLETED'),
            (10, 'jack',   130.00, 'USD', 'FAILED'),
        ]
        for row in data:
            rows.append(','.join(str(v) for v in row))
        upload_to_s3(S3_BUCKET, KEY, '\n'.join(rows).encode())
        print(f"Uploaded {len(data)} rows to s3://{S3_BUCKET}/{KEY}")
        return len(data)

    @task
    def create_table():
        from utils.commons import execute_snowflake, read_query
        execute_snowflake(f"CREATE DATABASE IF NOT EXISTS {DATABASE}")
        execute_snowflake(f"CREATE SCHEMA IF NOT EXISTS {DATABASE}.{SCHEMA}")
        execute_snowflake(read_query(QUERIES_PATH, 'lab_11_create_transactions.sql', PARAMS))

    @task
    def load_from_s3():
        from utils.commons import execute_snowflake, read_query
        params = {
            **PARAMS,
            'aws_key_id':     os.getenv('AWS_ACCESS_KEY_ID'),
            'aws_secret_key': os.getenv('AWS_SECRET_ACCESS_KEY'),
        }
        execute_snowflake(read_query(QUERIES_PATH, 'lab_11_copy_into.sql', params))
        print("Data loaded from S3.")

    @task
    def validate(expected_rows: int):
        from utils.commons import snowflake_to_pandas
        df = snowflake_to_pandas(f"SELECT * FROM {TABLE} ORDER BY id")
        print(df.to_string(index=False))
        summary = snowflake_to_pandas(f"""
            SELECT
                COUNT(*)                                        AS total_rows,
                SUM(amount)                                     AS total_amount,
                COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) AS completed,
                COUNT(CASE WHEN status = 'FAILED'    THEN 1 END) AS failed
            FROM {TABLE}
        """)
        print("\nSummary:")
        print(summary.to_string(index=False))
        assert int(summary['TOTAL_ROWS'].iloc[0]) == expected_rows, \
            f"Expected {expected_rows} rows, got {summary['TOTAL_ROWS'].iloc[0]}"
        print("\nValidation passed!")

    # -------------------- Task Dependencies --------------------
    n = generate_and_upload()
    create_table() >> load_from_s3() >> validate(n)
