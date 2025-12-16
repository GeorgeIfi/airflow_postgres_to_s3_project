from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.models import Connection
from airflow import settings
import os

def create_connections():
    # Create PostgreSQL connection
    postgres_conn = Connection(
        conn_id='data_postgres_conn',
        conn_type='postgres',
        host='data_postgres',
        schema='datadb',
        login='datauser',
        password='datapass',
        port=5432
    )
    
    # Create AWS connection
    aws_conn = Connection(
        conn_id='aws_default',
        conn_type='aws',
        extra='{"region_name": "us-east-1"}'
    )
    
    # Add connections to Airflow
    session = settings.Session()
    
    # Delete existing connections if they exist
    existing_postgres = session.query(Connection).filter(Connection.conn_id == 'data_postgres_conn').first()
    if existing_postgres:
        session.delete(existing_postgres)
        session.commit()
    
    existing_aws = session.query(Connection).filter(Connection.conn_id == 'aws_default').first()
    if existing_aws:
        session.delete(existing_aws)
        session.commit()
    
    # Add new connections
    session.add(postgres_conn)
    session.add(aws_conn)
    session.commit()
    session.close()
    
    print("Connections created successfully!")

dag = DAG(
    'setup_connections',
    description='Setup PostgreSQL and AWS connections',
    schedule_interval=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['setup']
)

setup_task = PythonOperator(
    task_id='create_connections',
    python_callable=create_connections,
    dag=dag
)