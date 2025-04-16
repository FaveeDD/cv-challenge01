#!/bin/bash

# Function to check if RDS is accessible
check_rds_connection() {
  echo "Checking connection to Amazon RDS PostgreSQL..."
  
  export PGPASSWORD=${POSTGRES_PASSWORD}
  if psql -h ${POSTGRES_SERVER} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c '\q' >/dev/null 2>&1; then
    echo "✅ Successfully connected to RDS instance at ${POSTGRES_SERVER}"
    return 0
  else
    echo "❌ Failed to connect to RDS instance at ${POSTGRES_SERVER}"
    echo "Please verify your RDS instance is running and your security group allows connections."
    return 1
  fi
}

# Create necessary directories if they don't exist
mkdir -p monitoring/prometheus
mkdir -p monitoring/grafana/provisioning/datasources
mkdir -p monitoring/grafana/provisioning/dashboards
mkdir -p monitoring/loki
mkdir -p monitoring/promtail
mkdir -p traefik/config
mkdir -p traefik/certificates
mkdir -p backend/scripts

# Create Docker networks if they don't exist
echo "Creating Docker networks..."
docker network create monitoring-network || true
docker network create app-network || true

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ .env file not found. Please create one with your RDS credentials."
  exit 1
fi

# Check RDS connection before starting the services
if ! check_rds_connection; then
  echo "Would you like to continue anyway? (y/n)"
  read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Deployment aborted. Please verify your RDS configuration."
    exit 1
  fi
fi

# Start the monitoring stack first
echo "Starting monitoring stack..."
docker-compose -f docker-compose.monitoring.yml up -d

# Wait for monitoring services to be ready
echo "Waiting for monitoring services to be ready..."
sleep 10

# Start the application stack
echo "Starting application stack..."
docker-compose -f docker-compose.app.yml up -d

# Check if the backend container is running
if [ "$(docker ps -q -f name=fastapi-backend)" ]; then
  echo "Running database initialization script..."
  docker exec fastapi-backend bash -c "cd /app && bash ./scripts/postgres-init.sh"
else
  echo "❌ Backend container is not running. Check docker logs for details."
  docker-compose -f docker-compose.app.yml logs backend
  exit 1
fi

echo "Deployment completed!"
echo "----------------------------"
echo "Access the application at: https://${DOMAIN}"
echo "Access Grafana at: https://${DOMAIN}/grafana"
echo "Access Prometheus at: https://${DOMAIN}/prometheus"
echo "Access Traefik Dashboard at: https://traefik.${DOMAIN}"
echo "Access Adminer at: https://db.${DOMAIN}"
echo "(Use Adminer to connect to your RDS instance directly)"
echo "----------------------------"