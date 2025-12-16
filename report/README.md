# Airflow PostgreSQL to S3 ETL

A data pipeline project that extracts data from PostgreSQL and loads it to AWS S3 using Apache Airflow.

## Project Structure

```
├── dags/                 # Airflow DAG definitions
├── plugins/              # Custom Airflow plugins
├── logs/                 # Airflow logs
├── tests/                # Test files
├── .devcontainer/        # Dev container configuration
├── requirements.txt      # Python dependencies
├── .env.example          # Example environment variables
└── docker-compose.yml    # Docker compose for local development
```

## Quick Start

### Using Dev Container

1. Open the project in VS Code
2. Install the Dev Containers extension
3. Click "Reopen in Container"

### Local Development

1. Create a `.env` file from `.env.example`
2. Install dependencies: `pip install -r requirements.txt`
3. Initialize Airflow: `airflow db init`
4. Start the webserver: `airflow webserver`

## Environment Variables

See `.env.example` for required configuration.
