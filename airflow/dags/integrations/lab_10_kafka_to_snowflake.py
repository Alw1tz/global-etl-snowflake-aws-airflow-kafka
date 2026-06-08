"""
Kafka → Snowflake via Kafka Connect.

--------
* DAG Name:
    lab_10_kafka_to_snowflake
* Owner:
    alw1tz
* Description:
    Produce events to Kafka, then configure the Snowflake Sink Connector
    via the Kafka Connect REST API to stream them into Snowflake.

    NOTE: The Snowflake Kafka connector requires key-pair (RSA) authentication.
    Setup steps:
      1. Generate RSA key pair and register the public key in Snowflake:
           ALTER USER <user> SET RSA_PUBLIC_KEY='<public_key>';
      2. Set SNOWFLAKE_PRIVATE_KEY in .env (base64-encoded private key, no headers).
    Ref: https://docs.snowflake.com/en/user-guide/kafka-connector-install
"""
from __future__ import annotations

import json
import os
import pendulum
from airflow import DAG
from airflow.decorators import task

from utils.settings import get_default_args, KAFKA_BROKER

# -------------------- Globals --------------------
TOPIC          = 'lab-sf-events'
CONNECTOR_NAME = 'snowflake-sink-lab'
CONNECT_URL    = 'http://kafka-connect:8083'

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_10_kafka_to_snowflake',
    description='Kafka Connect Snowflake sink — produce events and configure connector.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['kafka', 'snowflake', 'lab'],
) as dag:

    @task
    def produce_events():
        from utils.commons import create_producer_template
        producer = create_producer_template(KAFKA_BROKER)
        for i in range(10):
            msg = {'id': i, 'value': f'record_{i}', 'source': 'lab_10'}
            producer.produce(TOPIC, key=str(i).encode(), value=json.dumps(msg).encode())
        producer.flush()
        print(f"Produced 10 messages to '{TOPIC}'")

    @task
    def check_connectors():
        import requests
        r       = requests.get(f'{CONNECT_URL}/connectors')
        plugins = requests.get(f'{CONNECT_URL}/connector-plugins')
        sf      = [p for p in plugins.json() if 'snowflake' in p['class'].lower()]
        print(f"Active connectors: {r.json()}")
        print(f"Snowflake plugin installed: {bool(sf)}")
        if sf:
            print(f"  → {sf[0]['class']}")

    @task
    def create_connector():
        import requests
        private_key = os.getenv('SNOWFLAKE_PRIVATE_KEY', '')
        if not private_key:
            print("SNOWFLAKE_PRIVATE_KEY not set — connector requires key-pair auth.")
            print("See DAG docstring for setup steps.")
            return
        config = {
            'name': CONNECTOR_NAME,
            'config': {
                'connector.class':                'com.snowflake.kafka.connector.SnowflakeSinkConnector',
                'tasks.max':                      '1',
                'topics':                         TOPIC,
                'snowflake.url.name':             f"{os.getenv('SNOWFLAKE_ACCOUNT')}.snowflakecomputing.com",
                'snowflake.user.name':            os.getenv('SNOWFLAKE_USER'),
                'snowflake.private.key':          private_key,
                'snowflake.database.name':        'LABS_DB',
                'snowflake.schema.name':          'LABS',
                'key.converter':                  'org.apache.kafka.connect.storage.StringConverter',
                'value.converter':                'org.apache.kafka.connect.json.JsonConverter',
                'value.converter.schemas.enable': 'false',
            },
        }
        r = requests.post(f'{CONNECT_URL}/connectors', json=config,
                          headers={'Content-Type': 'application/json'})
        print(f"Connector creation: {r.status_code}")
        print(r.json())

    # -------------------- Task Dependencies --------------------
    produce_events() >> check_connectors() >> create_connector()
