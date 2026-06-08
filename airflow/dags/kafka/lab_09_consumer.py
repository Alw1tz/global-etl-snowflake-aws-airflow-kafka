"""
Kafka consumer — read and aggregate events from a topic.

--------
* DAG Name:
    lab_09_consumer
* Owner:
    alw1tz
* Description:
    Consumes messages from 'lab-events' and groups them by event type.
    Uses confluent-kafka Consumer with earliest offset reset so it always
    reads from the beginning of the topic.
    Run lab_08 first to populate the topic.
"""
from __future__ import annotations

import json
import pendulum
from airflow import DAG
from airflow.decorators import task

from utils.settings import get_default_args, KAFKA_BROKER

# -------------------- Globals --------------------
TOPIC          = 'lab-events'
CONSUMER_GROUP = 'lab-consumer-group'

# -------------------- DAG --------------------
with DAG(
    dag_id='lab_09_consumer',
    description='Consume from a Kafka topic and group by event type.',
    schedule=None,
    start_date=pendulum.datetime(2025, 1, 1, tz='UTC'),
    default_args=get_default_args('alw1tz'),
    catchup=False,
    tags=['kafka', 'lab'],
) as dag:

    @task
    def consume_messages():
        from confluent_kafka import Consumer, KafkaException
        consumer = Consumer({
            'bootstrap.servers': KAFKA_BROKER,
            'group.id':          CONSUMER_GROUP,
            'auto.offset.reset': 'earliest',
        })
        consumer.subscribe([TOPIC])
        messages = []
        try:
            while True:
                msg = consumer.poll(timeout=3.0)
                if msg is None:
                    break
                if msg.error():
                    raise KafkaException(msg.error())
                data = json.loads(msg.value().decode('utf-8'))
                messages.append(data)
                print(f"Consumed ← {data}")
        finally:
            consumer.close()

        print(f"\nTotal consumed: {len(messages)} messages")
        by_event = {}
        for m in messages:
            by_event[m['event']] = by_event.get(m['event'], 0) + 1
        print("Events by type:", by_event)
        return len(messages)

    # -------------------- Task Dependencies --------------------
    consume_messages()
