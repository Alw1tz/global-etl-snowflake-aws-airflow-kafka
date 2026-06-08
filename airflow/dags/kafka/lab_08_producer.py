"""
Kafka producer — publish JSON events to a topic.

--------
* DAG Name:
    lab_08_producer
* Owner:
    alw1tz
* Description:
    Produces a batch of JSON events to the 'lab-events' Kafka topic.
    Uses confluent-kafka Producer via the create_producer_template helper.
    Run this before lab_09 (consumer) to have messages ready to consume.
"""
from __future__ import annotations

import json
import pendulum
from airflow import DAG
from airflow.decorators import task

from utils.settings import get_default_args, KAFKA_BROKER

# -------------------- Globals --------------------
TOPIC = 'lab-events'

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_08_producer',
    description='Produce JSON events to a Kafka topic.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['kafka', 'lab'],
) as dag:

    @task
    def produce_messages():
        from utils.commons import create_producer_template
        producer = create_producer_template(KAFKA_BROKER)
        events = [
            {'id': 1, 'event': 'PURCHASE', 'user': 'alice',  'amount': 99.99},
            {'id': 2, 'event': 'CLICK',    'user': 'bob',    'page': '/checkout'},
            {'id': 3, 'event': 'LOGIN',    'user': 'carlos', 'ip': '10.0.0.1'},
            {'id': 4, 'event': 'PURCHASE', 'user': 'diana',  'amount': 49.50},
            {'id': 5, 'event': 'LOGOUT',   'user': 'eve'},
        ]
        for event in events:
            producer.produce(
                topic=TOPIC,
                key=str(event['id']).encode(),
                value=json.dumps(event).encode(),
            )
            print(f"Produced → {event}")
        producer.flush()
        print(f"\nFlushed {len(events)} messages to topic '{TOPIC}'")

    # -------------------- Task Dependencies --------------------
    produce_messages()
