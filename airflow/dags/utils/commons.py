"""Reusable utilities for all DAGs — mirrors commons.py pattern from work repo."""
from contextlib import closing

import boto3
import pandas as pd
from confluent_kafka import Producer

from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

from utils.settings import SNOWFLAKE_CONN_ID, AWS_CONN_ID, KAFKA_BROKER


# ── Snowflake ─────────────────────────────────────────────────────────────────

def execute_snowflake(sql: str, conn_id: str = SNOWFLAKE_CONN_ID, with_cursor: bool = False):
    """Execute a Snowflake query. Mirrors work repo execute_snowflake()."""
    hook = SnowflakeHook(snowflake_conn_id=conn_id)
    with closing(hook.get_conn()) as conn:
        with closing(conn.cursor()) as cur:
            print(sql)
            cur.execute(sql)
            res = cur.fetchall()
            return (res, cur) if with_cursor else res


def snowflake_to_pandas(sql: str, conn_id: str = SNOWFLAKE_CONN_ID) -> pd.DataFrame:
    """Run a SELECT and return results as DataFrame. Mirrors work repo snowflake_to_pandas()."""
    result, cur = execute_snowflake(sql, conn_id, with_cursor=True)
    headers = [col[0] for col in cur.description]
    df = pd.DataFrame(result, columns=headers)
    return df


def read_query(path: str, filename: str, params: dict = None) -> str:
    """Read a .sql file from the given path and optionally format with params."""
    import os
    with open(os.path.join(path, filename)) as f:
        sql = f.read().strip()
    if params:
        sql = sql.format(**params)
    return sql


# ── AWS S3 ────────────────────────────────────────────────────────────────────

def upload_to_s3(bucket: str, key: str, data: bytes, conn_id: str = AWS_CONN_ID) -> None:
    """Upload bytes to an S3 object."""
    S3Hook(aws_conn_id=conn_id).load_bytes(data, key=key, bucket_name=bucket, replace=True)


def download_from_s3(bucket: str, key: str, conn_id: str = AWS_CONN_ID) -> str:
    """Download an S3 object and return its content as string."""
    return S3Hook(aws_conn_id=conn_id).read_key(key=key, bucket_name=bucket)


def list_s3_objects(bucket: str, prefix: str = '', conn_id: str = AWS_CONN_ID) -> list:
    """List object keys in an S3 bucket under a prefix."""
    return S3Hook(aws_conn_id=conn_id).list_keys(bucket_name=bucket, prefix=prefix) or []


def get_s3_client(conn_id: str = AWS_CONN_ID):
    """Return a raw boto3 S3 client using the Airflow AWS connection."""
    from airflow.providers.amazon.aws.hooks.base_aws import AwsBaseHook
    hook = AwsBaseHook(aws_conn_id=conn_id, client_type='s3')
    creds = hook.get_credentials()
    return boto3.client(
        's3',
        aws_access_key_id=creds.access_key,
        aws_secret_access_key=creds.secret_key,
        region_name=hook.conn_config.region_name or 'us-east-1',
    )


# ── Kafka ─────────────────────────────────────────────────────────────────────

def create_producer_template(broker: str = KAFKA_BROKER) -> Producer:
    """Create a Kafka producer. Mirrors work repo create_producer_template()."""
    return Producer({
        'bootstrap.servers': broker,
        'queue.buffering.max.messages': 1_000_000,
    })
