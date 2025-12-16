#!/bin/bash
set -e

echo "Installing Python dependencies..."
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

echo "Setting up Airflow environment..."
export AIRFLOW_HOME=${AIRFLOW_HOME:-~/airflow}
export AIRFLOW__CORE__LOAD_EXAMPLES=False
export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=${AIRFLOW__DATABASE__SQL_ALCHEMY_CONN:-sqlite:////home/vscode/airflow/airflow.db}

echo "Initializing Airflow database..."
airflow db migrate

echo "Dev container setup complete!"
echo "Airflow webserver will be available at http://localhost:8080"
echo "Default credentials: airflow / airflow"
