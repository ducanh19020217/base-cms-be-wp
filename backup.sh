#!/bin/bash

# 1. Export Database
echo "Exporting database..."
docker compose exec -T wordpress wp db export data.sql --allow-root

# 2. Create Archive
echo "Creating backup archive..."
tar -czvf full_site_backup.tar.gz \
    docker-compose.yml \
    wp-content \
    .htaccess \
    wp-config.php \
    data.sql

# 3. Cleanup
rm data.sql

echo "Backup complete! Transfer 'full_site_backup.tar.gz' to your new machine."
