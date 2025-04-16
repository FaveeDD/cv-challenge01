#!/bin/bash

echo "Checking Amazon RDS PostgreSQL connection and initializing if needed..."

# Wait for RDS to be ready
MAX_RETRIES=30
RETRY_COUNT=0

export PGPASSWORD=$POSTGRES_PASSWORD

until psql -h "$POSTGRES_SERVER" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q'; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Failed to connect to Amazon RDS PostgreSQL after $MAX_RETRIES attempts. Exiting."
    exit 1
  fi
  echo "RDS PostgreSQL is unavailable - sleeping for 2 seconds (attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 2
done

echo "Amazon RDS PostgreSQL is up and running!"

# Check if the database tables already exist
TABLES=$(psql -h "$POSTGRES_SERVER" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")

if [ "$TABLES" -eq "0" ]; then
  echo "No tables found in the database. Running migrations..."
  
  # Run the prestart script that initializes the database
  bash ./prestart.sh
  
  echo "Database initialization completed!"
else
  echo "Database already contains tables. Skipping initialization."
fi

echo "Amazon RDS PostgreSQL setup completed successfully!"