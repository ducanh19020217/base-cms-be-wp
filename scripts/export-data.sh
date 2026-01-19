#!/bin/bash

# Export WordPress data (database + uploads)
# Usage: ./scripts/export-data.sh [output-file]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE=${1:-"wordpress-backup-${TIMESTAMP}.tar.gz"}
TEMP_DIR="/tmp/wp-export-${TIMESTAMP}"

echo -e "${GREEN}=== Exporting WordPress Data ===${NC}"
echo -e "Output: ${YELLOW}${OUTPUT_FILE}${NC}"
echo ""

# Create temp directory
mkdir -p "${TEMP_DIR}"

# Export database
echo -e "${GREEN}[1/3] Exporting database...${NC}"
docker exec wp-backend-1 mysqldump \
    -h db \
    -u wordpress \
    -pwordpress \
    wordpress \
    > "${TEMP_DIR}/database.sql"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database exported ($(du -h "${TEMP_DIR}/database.sql" | cut -f1))${NC}"
else
    echo -e "${RED}✗ Database export failed${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Sanitize database (remove sensitive data)
echo -e "${GREEN}[2/3] Sanitizing database...${NC}"
# Remove WooCommerce API keys (they will be regenerated on import)
sed -i '/woocommerce_api_keys/d' "${TEMP_DIR}/database.sql"
# Remove user passwords (they will be reset on import)
sed -i 's/user_pass.*,/user_pass = "RESET_ON_IMPORT",/g' "${TEMP_DIR}/database.sql"
echo -e "${GREEN}✓ Sensitive data removed${NC}"

# Export uploads
echo -e "${GREEN}[3/3] Exporting uploads...${NC}"
docker cp wp-backend-1:/var/www/html/wp-content/uploads "${TEMP_DIR}/uploads"

if [ $? -eq 0 ]; then
    UPLOADS_SIZE=$(du -sh "${TEMP_DIR}/uploads" | cut -f1)
    echo -e "${GREEN}✓ Uploads exported (${UPLOADS_SIZE})${NC}"
else
    echo -e "${YELLOW}⚠ No uploads found or export failed${NC}"
fi

# Create archive
echo -e "${GREEN}Creating archive...${NC}"
cd "${TEMP_DIR}"
tar -czf "../${OUTPUT_FILE}" .
cd - > /dev/null

# Cleanup
rm -rf "${TEMP_DIR}"

# Summary
FINAL_SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)
echo ""
echo -e "${GREEN}=== Export Complete ===${NC}"
echo -e "Backup file: ${YELLOW}${OUTPUT_FILE}${NC}"
echo -e "Size: ${YELLOW}${FINAL_SIZE}${NC}"
echo ""
echo -e "Contents:"
echo -e "  - database.sql (sanitized)"
echo -e "  - uploads/ (wp-content/uploads)"
echo ""
echo -e "${YELLOW}Note: API keys and passwords have been removed for security${NC}"
echo -e "Import with: ${YELLOW}./scripts/import-data.sh ${OUTPUT_FILE}${NC}"
