#!/bin/bash

# Deploy WordPress + Next.js stack from Docker Hub
# Usage: ./scripts/deploy.sh [version]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VERSION=${1:-latest}
DOCKER_USERNAME=${DOCKER_USERNAME:-"your-dockerhub-username"}

echo -e "${GREEN}=== Deploying Stack ===${NC}"
echo -e "Version: ${YELLOW}${VERSION}${NC}"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo -e "Copy .env.example to .env and configure it:"
    echo -e "  ${YELLOW}cp .env.example .env${NC}"
    echo -e "  ${YELLOW}nano .env${NC}"
    exit 1
fi

# Check if frontend .env.production exists
if [ ! -f "frontend/.env.production" ]; then
    echo -e "${YELLOW}Warning: frontend/.env.production not found${NC}"
    echo -e "Creating from .env.local..."
    if [ -f "frontend/.env.local" ]; then
        cp frontend/.env.local frontend/.env.production
    fi
fi

# Pull latest images
echo -e "${GREEN}Pulling images from Docker Hub...${NC}"
export DOCKER_USERNAME="${DOCKER_USERNAME}"
export VERSION="${VERSION}"
docker-compose pull

# Stop existing containers
echo -e "${GREEN}Stopping existing containers...${NC}"
docker-compose down

# Start services
echo -e "${GREEN}Starting services...${NC}"
docker-compose up -d

# Wait for services to be healthy
echo -e "${GREEN}Waiting for services to be ready...${NC}"
sleep 10

# Check service status
echo ""
echo -e "${GREEN}=== Service Status ===${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo -e "Services are running:"
echo -e "  - WordPress Backend: ${YELLOW}http://localhost:6060${NC}"
echo -e "  - Next.js Frontend: ${YELLOW}http://localhost:3000${NC}"
echo ""
echo -e "View logs: ${YELLOW}docker-compose logs -f${NC}"
