#!/bin/bash

# API Testing Script
# Tests all API endpoints of the BMI Health Tracker application

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BASE_URL="${API_URL:-http://localhost}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}BMI Health Tracker - API Tests${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${GREEN}Base URL: ${BASE_URL}${NC}"

# Test health endpoint
echo -e "\n${YELLOW}Testing Health Endpoint...${NC}"
if curl -s "${BASE_URL}/api/health" | jq . > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Health endpoint: OK${NC}"
    curl -s "${BASE_URL}/api/health" | jq .
else
    echo -e "${RED}✗ Health endpoint: FAILED${NC}"
fi

# Test API info endpoint
echo -e "\n${YELLOW}Testing API Info Endpoint...${NC}"
if curl -s "${BASE_URL}/api" | jq . > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API info endpoint: OK${NC}"
    curl -s "${BASE_URL}/api" | jq .
else
    echo -e "${RED}✗ API info endpoint: FAILED${NC}"
fi

# Test get all measurements
echo -e "\n${YELLOW}Testing GET /api/measurements...${NC}"
if curl -s "${BASE_URL}/api/measurements" | jq . > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Get measurements: OK${NC}"
    COUNT=$(curl -s "${BASE_URL}/api/measurements" | jq '.count')
    echo "Total measurements: $COUNT"
else
    echo -e "${RED}✗ Get measurements: FAILED${NC}"
fi

# Test create measurement
echo -e "\n${YELLOW}Testing POST /api/measurements...${NC}"
MEASUREMENT_ID=$(curl -s -X POST "${BASE_URL}/api/measurements" \
    -H "Content-Type: application/json" \
    -d '{
        "height": 1.75,
        "weight": 80.5,
        "measurement_date": "'$(date +%Y-%m-%d)'",
        "notes": "Test measurement"
    }' | jq -r '.data.id // empty')

if [ -n "$MEASUREMENT_ID" ]; then
    echo -e "${GREEN}✓ Create measurement: OK${NC}"
    echo "Created measurement ID: $MEASUREMENT_ID"
else
    echo -e "${RED}✗ Create measurement: FAILED${NC}"
fi

# Test get single measurement
if [ -n "$MEASUREMENT_ID" ]; then
    echo -e "\n${YELLOW}Testing GET /api/measurements/{id}...${NC}"
    if curl -s "${BASE_URL}/api/measurements/${MEASUREMENT_ID}" | jq . > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Get measurement by ID: OK${NC}"
        curl -s "${BASE_URL}/api/measurements/${MEASUREMENT_ID}" | jq '.data'
    else
        echo -e "${RED}✗ Get measurement by ID: FAILED${NC}"
    fi
fi

# Test update measurement
if [ -n "$MEASUREMENT_ID" ]; then
    echo -e "\n${YELLOW}Testing PUT /api/measurements/{id}...${NC}"
    if curl -s -X PUT "${BASE_URL}/api/measurements/${MEASUREMENT_ID}" \
        -H "Content-Type: application/json" \
        -d '{
            "weight": 79.5,
            "notes": "Updated test measurement"
        }' | jq . > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Update measurement: OK${NC}"
    else
        echo -e "${RED}✗ Update measurement: FAILED${NC}"
    fi
fi

# Test statistics
echo -e "\n${YELLOW}Testing GET /api/measurements/stats/summary...${NC}"
if curl -s "${BASE_URL}/api/measurements/stats/summary" | jq . > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Statistics endpoint: OK${NC}"
    curl -s "${BASE_URL}/api/measurements/stats/summary" | jq '.data'
else
    echo -e "${RED}✗ Statistics endpoint: FAILED${NC}"
fi

# Test delete measurement
if [ -n "$MEASUREMENT_ID" ]; then
    echo -e "\n${YELLOW}Testing DELETE /api/measurements/{id}...${NC}"
    if curl -s -X DELETE "${BASE_URL}/api/measurements/${MEASUREMENT_ID}" | jq . > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Delete measurement: OK${NC}"
    else
        echo -e "${RED}✗ Delete measurement: FAILED${NC}"
    fi
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}API Testing Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
