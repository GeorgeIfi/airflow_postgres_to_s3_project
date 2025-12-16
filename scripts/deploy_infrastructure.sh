# This script automates Terraform deployment for your AWS infrastructure.

#!/bin/bash

# Deploy AWS infrastructure using Terraform

set -e # means Exit immediately if a command exits with a non-zero status

echo "Deploying AWS infrastructure..." # means Starting the deployment process

cd terraform # means Change directory to where Terraform configuration files are located

# Initialize Terraform
terraform init 

# Plan the deployment
terraform plan -var="project_name=airflow-etl" -var="environment=dev"

# Apply the configuration
terraform apply -auto-approve -var="project_name=airflow-etl" -var="environment=dev"

# Output the results
echo "Infrastructure deployed successfully!"
echo "S3 Bucket: $(terraform output -raw s3_bucket_name)"
echo "Glue Database: $(terraform output -raw glue_database_name)"
echo "Athena Workgroup: $(terraform output -raw athena_workgroup_name)"

cd .. # means Change back to the original directory
