"""Global sandbox settings — mirrors production pattern from work repo."""
import os
from copy import deepcopy
from datetime import datetime, timedelta

# ── Environment ──────────────────────────────────────────────────────────────
AIRFLOW_ENVIRONMENT = os.getenv('AIRFLOW_ENVIRONMENT', 'local')
IS_LOCAL      = AIRFLOW_ENVIRONMENT == 'local'
IS_PRODUCTION = AIRFLOW_ENVIRONMENT == 'production'

# ── Airflow connection IDs ────────────────────────────────────────────────────
SNOWFLAKE_CONN_ID = 'snowflake_default'
AWS_CONN_ID       = 'aws_default'

# ── Kafka ─────────────────────────────────────────────────────────────────────
KAFKA_BROKER = os.getenv('KAFKA_BROKER', 'kafka:29092')

# ── S3 ────────────────────────────────────────────────────────────────────────
S3_BUCKET = os.getenv('S3_BUCKET', 'labs-sandbox-alw1tz')

# ── Snowflake (raw env vars — used when building connections via init) ────────
SF_ACCOUNT   = os.getenv('SNOWFLAKE_ACCOUNT', '')
SF_USER      = os.getenv('SNOWFLAKE_USER', '')
SF_PASSWORD  = os.getenv('SNOWFLAKE_PASSWORD', '')
SF_DATABASE  = os.getenv('SNOWFLAKE_DATABASE', 'LABS_DB')
SF_WAREHOUSE = os.getenv('SNOWFLAKE_WAREHOUSE', 'COMPUTE_WH')
SF_SCHEMA    = os.getenv('SNOWFLAKE_SCHEMA', 'PUBLIC')
SF_ROLE      = os.getenv('SNOWFLAKE_ROLE', 'SYSADMIN')


def get_default_args(owner: str = 'airflow') -> dict:
    """Default DAG args factory — same pattern as work repo."""
    return deepcopy({
        'owner': owner,
        'depends_on_past': False,
        'start_date': datetime(2025, 1, 1),
        'retries': 1,
        'retry_delay': timedelta(minutes=5),
        'email_on_failure': False,
        'email_on_retry': False,
    })
