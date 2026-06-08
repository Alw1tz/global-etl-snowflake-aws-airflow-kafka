"""
S3 to Snowflake — COPY INTO pattern.

--------
* DAG Name:
    lab_07_s3_to_snowflake
* Owner:
    alw1tz
* Description:
    Upload a CSV to S3 then load it into Snowflake using COPY INTO.
    Demonstrates the most common bulk-load pattern for production pipelines.
    Credentials are resolved at task execution time from the Airflow connection.
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
TABLE    = f'{DATABASE}.{SCHEMA}.S3_LOAD'
KEY      = 'snowflake-stage/transactions.csv'

PARAMS       = {'database': DATABASE, 'schema': SCHEMA, 'table': TABLE, 'bucket': S3_BUCKET, 'key': KEY}
QUERIES_PATH = os.path.join(os.path.dirname(__file__), 'queries')

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_07_s3_to_snowflake',
    description='Upload CSV to S3 then COPY INTO Snowflake.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['aws', 'snowflake', 'lab'],
) as dag:

    @task
    def upload_csv():
        from utils.commons import get_s3_client, upload_to_s3
        s3 = get_s3_client()
        try:
            s3.create_bucket(Bucket=S3_BUCKET)
        except Exception:
            pass
        csv = (
            "id,user_name,amount,status\n"
            "1,alice,150.00,COMPLETED\n"
            "2,bob,89.99,PENDING\n"
            "3,carlos,320.50,COMPLETED\n"
            "4,diana,45.00,FAILED\n"
            "5,eve,200.00,COMPLETED\n"
        )
        upload_to_s3(S3_BUCKET, KEY, csv.encode())
        print(f"CSV uploaded: s3://{S3_BUCKET}/{KEY}")

    @task
    def create_table():
        from utils.commons import execute_snowflake
        execute_snowflake(f"CREATE DATABASE IF NOT EXISTS {DATABASE}")
        execute_snowflake(f"CREATE SCHEMA IF NOT EXISTS {DATABASE}.{SCHEMA}")
        execute_snowflake(f"""
            CREATE OR REPLACE TABLE {TABLE} (
                id        NUMBER,
                user_name VARCHAR(100),
                amount    FLOAT,
                status    VARCHAR(50)
            )
        """)

    @task
    def copy_into():
        from utils.commons import execute_snowflake, read_query
        params = {
            **PARAMS,
            'aws_key_id':     os.getenv('AWS_ACCESS_KEY_ID'),
            'aws_secret_key': os.getenv('AWS_SECRET_ACCESS_KEY'),
        }
        execute_snowflake(read_query(QUERIES_PATH, 'lab_07_copy_into.sql', params))
        print("COPY INTO executed.")

    @task
    def validate():
        from utils.commons import snowflake_to_pandas
        df    = snowflake_to_pandas(f"SELECT * FROM {TABLE} ORDER BY id")
        count = snowflake_to_pandas(f"SELECT COUNT(*) AS total FROM {TABLE}")
        print(df.to_string(index=False))
        print(f"\nTotal rows loaded: {count['TOTAL'].iloc[0]}")

    # -------------------- Task Dependencies --------------------
    upload_csv() >> create_table() >> copy_into() >> validate()
