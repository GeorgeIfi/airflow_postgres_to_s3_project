from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.postgres_operator import PostgresOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'restore_sales_dump',
    default_args=default_args,
    description='Restore sales_db.dump to PostgreSQL',
    schedule_interval=None,  # Manual trigger only
    catchup=False,
    tags=['postgres', 'restore', 'dump'],
)

# Task to restore the dump file
restore_dump = BashOperator(
    task_id='restore_sales_dump',
    bash_command='''
    export PGPASSWORD=datapass
    psql -h data_postgres -p 5432 -U datauser -d datadb -f /dumps/sales_db.dump
    ''',
    dag=dag,
)

# Task to verify restoration
verify_restore = PostgresOperator(
    task_id='verify_restore',
    postgres_conn_id='data_postgres_conn',
    sql='''
    SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
    FROM pg_tables 
    WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    ''',
    dag=dag,
)

restore_dump >> verify_restore