#!/bin/bash

# Script to delete all data from S3 to avoid storage costs
# Make sure to set your AWS credentials in environment variables

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS credentials not set"
    echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
    exit 1
fi

S3_BUCKET=${S3_BUCKET:-shopease-stg}

echo "WARNING: This will delete ALL data from s3://$S3_BUCKET/"
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

# Delete all objects in the bucket
aws s3 rm s3://$S3_BUCKET/ --recursive

echo "All data deleted from S3"
echo "Storage cost is now $0"