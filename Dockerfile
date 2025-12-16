FROM apache/airflow:2.7.3-python3.11

USER root
RUN apt-get update && apt-get install -y postgresql-client curl unzip

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Create airflow user with proper permissions
RUN mkdir -p /opt/airflow && chown -R airflow:root /opt/airflow && chmod -R g+w /opt/airflow

USER airflow
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt