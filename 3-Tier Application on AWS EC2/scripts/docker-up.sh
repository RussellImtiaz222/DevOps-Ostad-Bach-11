#!/bin/bash

# Docker Build and Run Script for Local Development

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}3-Tier Application - Docker Setup${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo -e "${YELLOW}Please install Docker from https://www.docker.com/products/docker-desktop${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    echo -e "${YELLOW}Please install Docker Compose${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose found${NC}"

# Start containers
echo -e "\n${YELLOW}Starting services...${NC}"
docker-compose up -d

# Wait for services to be healthy
echo -e "\n${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Check service status
echo -e "\n${YELLOW}Checking service health...${NC}"

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres > /dev/null; then
    echo -e "${GREEN}✓ PostgreSQL: Ready${NC}"
else
    echo -e "${RED}✗ PostgreSQL: Not ready${NC}"
fi

# Check Backend
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend: Ready${NC}"
else
    echo -e "${RED}✗ Backend: Not ready (wait a few more seconds)${NC}"
fi

# Check Nginx
if curl -s http://localhost/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Nginx: Ready${NC}"
else
    echo -e "${RED}✗ Nginx: Not ready${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Services Started Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${BLUE}Access the application at:${NC}"
echo -e "  http://localhost"
echo -e "\n${BLUE}API Health Check:${NC}"
echo -e "  curl http://localhost/health"
echo -e "\n${BLUE}Useful Docker Compose Commands:${NC}"
echo -e "  docker-compose logs -f          # View logs"
echo -e "  docker-compose ps               # Show status"
echo -e "  docker-compose down             # Stop all services"
echo -e "  docker-compose restart          # Restart services"
