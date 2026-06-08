"""
Hello World DAG — sanity check.

--------
* DAG Name:
    lab_01_hello_world
* Owner:
    alw1tz
* Description:
    Confirms the Airflow scheduler is running and tasks execute correctly.
    No external dependencies — safe to trigger at any time.
"""
from __future__ import annotations

import pendulum
from airflow import DAG
from airflow.decorators import task

from utils.settings import get_default_args

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_01_hello_world',
    description='Sanity check — confirms Airflow is running.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['lab'],
) as dag:

    @task
    def say_hello():
        print("Hello from Airflow 3.x!")
        print("Scheduler is running. Tasks execute correctly.")

    # -------------------- Task Dependencies --------------------
    say_hello()
