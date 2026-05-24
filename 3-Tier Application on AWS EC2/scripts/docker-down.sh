#!/bin/bash

# Docker cleanup script

set -e

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Stopping Docker containers...${NC}"
docker-compose down -v

echo -e "${YELLOW}Containers stopped and volumes removed${NC}"
