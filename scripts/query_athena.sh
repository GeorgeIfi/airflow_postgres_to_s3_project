#!/bin/bash

# Query Athena from command line and display results
# Make sure to set your AWS credentials in environment variables

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS credentials not set"
    echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
    exit 1
fi

QUERY="$1"
S3_BUCKET=${S3_BUCKET:-shopease-stg}

if [ -z "$QUERY" ]; then
    echo "Usage: ./query_athena.sh 'SELECT * FROM shopease_catalog.daily_sales_summary LIMIT 10'"
    exit 1
fi

echo "Running query: $QUERY"
echo ""

# Start query execution
QUERY_ID=$(aws athena start-query-execution \
    --query-string "$QUERY" \
    --query-execution-context Database=shopease_catalog \
    --result-configuration OutputLocation=s3://$S3_BUCKET/athena-results/ \
    --work-group shopease-analytics \
    --query 'QueryExecutionId' \
    --output text)

echo "Query ID: $QUERY_ID"
echo "Waiting for results..."

# Wait for query to complete
aws athena wait query-succeeded --query-execution-id $QUERY_ID

# Get and display results
aws athena get-query-results \
    --query-execution-id $QUERY_ID \
    --output table

echo ""
echo "Query completed successfully!"