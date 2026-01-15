#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# 1. Extract Archive
echo "Extracting backup..."
tar -xzvf full_site_backup.tar.gz

# 2. Start Containers
echo "Starting Docker containers..."
docker compose up -d --wait

# 3. Import Database
echo "Importing database..."
# Wait a bit for MySQL to be fully ready
sleep 10
docker compose exec -T wordpress wp db import data.sql --allow-root

# 4. Cleanup
rm data.sql

echo "Restore complete! Your site is running at http://localhost:8082"
echo "API URL: http://localhost:8082/wp-json/wc/v3/products"
