from airflow.decorators import dag, task
from datetime import datetime


@dag(schedule=None, start_date=datetime(2025, 1, 1), catchup=False)
def hello_world():

    @task
    def say_hello():
        print("Hello, World!")

    say_hello()


hello_world()
