from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

dag = DAG(
    'trigger_glue_crawlers',
    default_args=default_args,
    description='Trigger Glue crawlers to update catalog after ETL',
    schedule_interval=None,
    catchup=False
)

# Trigger crawlers to catalog the data
trigger_crawlers = BashOperator(
    task_id='start_glue_crawlers',
    bash_command='''
    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
    export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
    
    echo "Starting Glue crawlers to catalog data..."
    
    aws glue start-crawler --name shopease-bronze-crawler || echo "Bronze crawler already running"
    aws glue start-crawler --name shopease-silver-crawler || echo "Silver crawler already running"
    aws glue start-crawler --name shopease-gold-crawler || echo "Gold crawler already running"
    
    echo "All crawlers triggered successfully!"
    echo "Tables will be available in Athena once crawlers complete (2-5 minutes)"
    ''',
    dag=dag
)