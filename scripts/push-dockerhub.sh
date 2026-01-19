#!/bin/bash

# Push Docker images to Docker Hub
# Usage: ./scripts/push-dockerhub.sh [version]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VERSION=${1:-latest}
DOCKER_USERNAME=${DOCKER_USERNAME:-"your-dockerhub-username"}
BACKEND_IMAGE="${DOCKER_USERNAME}/wordpress-backend"
FRONTEND_IMAGE="${DOCKER_USERNAME}/nextjs-frontend"

echo -e "${GREEN}=== Pushing Images to Docker Hub ===${NC}"
echo -e "Version: ${YELLOW}${VERSION}${NC}"
echo ""

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}Not logged in to Docker Hub. Logging in...${NC}"
    docker login
fi

# Verify images exist
if ! docker image inspect "${BACKEND_IMAGE}:${VERSION}" > /dev/null 2>&1; then
    echo -e "${RED}Error: Backend image ${BACKEND_IMAGE}:${VERSION} not found${NC}"
    echo -e "Run ${YELLOW}./scripts/build.sh ${VERSION}${NC} first"
    exit 1
fi

if ! docker image inspect "${FRONTEND_IMAGE}:${VERSION}" > /dev/null 2>&1; then
    echo -e "${RED}Error: Frontend image ${FRONTEND_IMAGE}:${VERSION} not found${NC}"
    echo -e "Run ${YELLOW}./scripts/build.sh ${VERSION}${NC} first"
    exit 1
fi

# Push backend
echo -e "${GREEN}[1/4] Pushing Backend (${VERSION})...${NC}"
docker push "${BACKEND_IMAGE}:${VERSION}"

echo -e "${GREEN}[2/4] Pushing Backend (latest)...${NC}"
docker push "${BACKEND_IMAGE}:latest"

# Push frontend
echo -e "${GREEN}[3/4] Pushing Frontend (${VERSION})...${NC}"
docker push "${FRONTEND_IMAGE}:${VERSION}"

echo -e "${GREEN}[4/4] Pushing Frontend (latest)...${NC}"
docker push "${FRONTEND_IMAGE}:latest"

# Summary
echo ""
echo -e "${GREEN}=== Push Complete ===${NC}"
echo -e "Images pushed to Docker Hub:"
echo -e "  - ${BACKEND_IMAGE}:${VERSION}"
echo -e "  - ${BACKEND_IMAGE}:latest"
echo -e "  - ${FRONTEND_IMAGE}:${VERSION}"
echo -e "  - ${FRONTEND_IMAGE}:latest"
echo ""
echo -e "View on Docker Hub:"
echo -e "  - https://hub.docker.com/r/${DOCKER_USERNAME}/wordpress-backend"
echo -e "  - https://hub.docker.com/r/${DOCKER_USERNAME}/nextjs-frontend"
