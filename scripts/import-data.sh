#!/bin/bash

# Import WordPress data (database + uploads)
# Usage: ./scripts/import-data.sh <backup-file>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_FILE=$1
TEMP_DIR="/tmp/wp-import-$(date +%Y%m%d_%H%M%S)"

if [ -z "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: Backup file not specified${NC}"
    echo -e "Usage: ./scripts/import-data.sh <backup-file>"
    exit 1
fi

if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: Backup file not found: ${BACKUP_FILE}${NC}"
    exit 1
fi

echo -e "${GREEN}=== Importing WordPress Data ===${NC}"
echo -e "Backup: ${YELLOW}${BACKUP_FILE}${NC}"
echo ""

# Extract archive
echo -e "${GREEN}Extracting backup...${NC}"
mkdir -p "${TEMP_DIR}"
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Check if database.sql exists
if [ ! -f "${TEMP_DIR}/database.sql" ]; then
    echo -e "${RED}Error: database.sql not found in backup${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Wait for database to be ready
echo -e "${GREEN}Waiting for database...${NC}"
sleep 5

# Import database
echo -e "${GREEN}[1/3] Importing database...${NC}"
docker exec -i wp-backend-1 mysql \
    -h db \
    -u wordpress \
    -pwordpress \
    wordpress \
    < "${TEMP_DIR}/database.sql"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database imported${NC}"
else
    echo -e "${RED}✗ Database import failed${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Import uploads
if [ -d "${TEMP_DIR}/uploads" ]; then
    echo -e "${GREEN}[2/3] Importing uploads...${NC}"
    docker cp "${TEMP_DIR}/uploads" wp-backend-1:/var/www/html/wp-content/
    docker exec wp-backend-1 chown -R www-data:www-data /var/www/html/wp-content/uploads
    echo -e "${GREEN}✓ Uploads imported${NC}"
else
    echo -e "${YELLOW}⚠ No uploads found in backup${NC}"
fi

# Reset admin password and create new API keys
echo -e "${GREEN}[3/3] Resetting admin credentials...${NC}"
docker exec wp-backend-1 wp user update admin \
    --user_pass=admin123 \
    --allow-root 2>/dev/null || echo -e "${YELLOW}⚠ Could not reset admin password (WP-CLI may not be available)${NC}"

# Cleanup
rm -rf "${TEMP_DIR}"

# Summary
echo ""
echo -e "${GREEN}=== Import Complete ===${NC}"
echo -e "Data has been imported successfully"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo -e "  1. Admin password has been reset to: ${YELLOW}admin123${NC}"
echo -e "  2. Please change it immediately after login"
echo -e "  3. Generate new WooCommerce API keys in WordPress admin"
echo -e "  4. Update .env files with new credentials"
echo ""
echo -e "Access WordPress: ${YELLOW}http://localhost:6060/wp-admin${NC}"
