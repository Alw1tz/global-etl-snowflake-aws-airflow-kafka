"""
AWS S3 basic operations.

--------
* DAG Name:
    lab_06_s3_operations
* Owner:
    alw1tz
* Description:
    Create bucket, upload a CSV, list objects, download content, and delete.
    Uses both S3Hook (Airflow-managed connection) and a raw boto3 client —
    demonstrates when to use each approach.
"""
from __future__ import annotations

import pendulum
from airflow import DAG
from airflow.decorators import task

from utils.settings import get_default_args, S3_BUCKET

# -------------------- Globals --------------------
KEY = 'labs/sample.csv'

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_06_s3_operations',
    description='S3 basics — create, upload, list, download, delete.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['aws', 'lab'],
) as dag:

    @task
    def create_bucket():
        from utils.commons import get_s3_client
        s3 = get_s3_client()
        try:
            s3.create_bucket(Bucket=S3_BUCKET)
            print(f"Bucket '{S3_BUCKET}' created.")
        except Exception:
            print(f"Bucket '{S3_BUCKET}' already exists.")

    @task
    def upload():
        from utils.commons import upload_to_s3
        data = b"id,name,amount\n1,Alice,100.0\n2,Bob,200.0\n3,Carlos,300.0"
        upload_to_s3(S3_BUCKET, KEY, data)
        print(f"Uploaded {len(data)} bytes to s3://{S3_BUCKET}/{KEY}")

    @task
    def list_objects():
        from utils.commons import list_s3_objects
        keys = list_s3_objects(S3_BUCKET, prefix='labs/')
        print(f"Objects under labs/: {keys}")

    @task
    def download_and_print():
        from utils.commons import download_from_s3
        content = download_from_s3(S3_BUCKET, KEY)
        print("File content:")
        print(content)

    @task
    def delete_object():
        from utils.commons import get_s3_client
        get_s3_client().delete_object(Bucket=S3_BUCKET, Key=KEY)
        print(f"Deleted s3://{S3_BUCKET}/{KEY}")

    # -------------------- Task Dependencies --------------------
    create_bucket() >> upload() >> list_objects() >> download_and_print() >> delete_object()
