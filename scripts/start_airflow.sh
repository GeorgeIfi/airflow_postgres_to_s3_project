#!/bin/bash

# Start Airflow services using Docker Compose

set -e # Exit immediately if a command exits with a non-zero status

echo "Starting Airflow ELT Pipeline..." # means Starting the Airflow services

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please update .env file with your AWS credentials and S3 bucket name"
    exit 1
fi

# Build and start services
docker-compose up --build -d

echo "Airflow services started successfully!"
echo "Airflow UI: http://localhost:8080"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "PostgreSQL (Source): localhost:5433"
echo "Username: postgres"
echo "Password: postgres"
echo "Database: source_db"