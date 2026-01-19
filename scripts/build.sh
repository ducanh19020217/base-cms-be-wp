#!/bin/bash

# Build script for WordPress + Next.js Docker images
# Usage: ./scripts/build.sh [version]

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

echo -e "${GREEN}=== Building Docker Images ===${NC}"
echo -e "Version: ${YELLOW}${VERSION}${NC}"
echo -e "Backend Image: ${YELLOW}${BACKEND_IMAGE}:${VERSION}${NC}"
echo -e "Frontend Image: ${YELLOW}${FRONTEND_IMAGE}:${VERSION}${NC}"
echo ""

# Validate environment
if [ ! -f ".env.example" ]; then
    echo -e "${RED}Error: .env.example not found. Please create it first.${NC}"
    exit 1
fi

# Build backend (WordPress)
echo -e "${GREEN}[1/2] Building Backend (WordPress)...${NC}"
cd "$(dirname "$0")/.."
docker build \
    -t "${BACKEND_IMAGE}:${VERSION}" \
    -t "${BACKEND_IMAGE}:latest" \
    -f Dockerfile \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backend build successful${NC}"
else
    echo -e "${RED}✗ Backend build failed${NC}"
    exit 1
fi

# Build frontend (Next.js)
echo -e "${GREEN}[2/2] Building Frontend (Next.js)...${NC}"
cd frontend

# Check if next.config.mjs has standalone output
if ! grep -q "output.*standalone" next.config.mjs 2>/dev/null; then
    echo -e "${YELLOW}Warning: next.config.mjs should have 'output: standalone' for production${NC}"
fi

docker build \
    -t "${FRONTEND_IMAGE}:${VERSION}" \
    -t "${FRONTEND_IMAGE}:latest" \
    -f Dockerfile \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend build successful${NC}"
else
    echo -e "${RED}✗ Frontend build failed${NC}"
    exit 1
fi

cd ..

# Summary
echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo -e "Images created:"
echo -e "  - ${BACKEND_IMAGE}:${VERSION}"
echo -e "  - ${BACKEND_IMAGE}:latest"
echo -e "  - ${FRONTEND_IMAGE}:${VERSION}"
echo -e "  - ${FRONTEND_IMAGE}:latest"
echo ""
echo -e "Next steps:"
echo -e "  1. Test images: ${YELLOW}docker-compose up${NC}"
echo -e "  2. Push to Docker Hub: ${YELLOW}./scripts/push-dockerhub.sh ${VERSION}${NC}"
