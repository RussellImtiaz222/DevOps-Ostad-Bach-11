#!/bin/bash

# Application Verification Script
# Test all components of the 3-tier application

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WEB_SERVER_1="${WEB_SERVER_1:-localhost}"
WEB_SERVER_2="${WEB_SERVER_2:-localhost}"
DATABASE_HOST="${DATABASE_HOST:-localhost}"
DATABASE_PORT="${DATABASE_PORT:-5432}"
DATABASE_USER="${DATABASE_USER:-appuser}"
DATABASE_PASSWORD="${DATABASE_PASSWORD:-apppassword}"
DATABASE_NAME="${DATABASE_NAME:-appdb}"

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_pattern="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${BLUE}[Test $TESTS_RUN] $test_name${NC}"
    
    if output=$(eval "$command" 2>&1); then
        if [[ -z "$expected_pattern" ]] || echo "$output" | grep -q "$expected_pattern"; then
            echo -e "${GREEN}✓ PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}✗ FAILED - Unexpected output${NC}"
            echo "Expected pattern: $expected_pattern"
            echo "Got: $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "${RED}✗ FAILED - Command error${NC}"
        echo "Error: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}3-Tier Application Verification${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "\n${YELLOW}Configuration:${NC}"
echo "Web Server 1: $WEB_SERVER_1"
echo "Web Server 2: $WEB_SERVER_2"
echo "Database: $DATABASE_HOST:$DATABASE_PORT"

# Database Tests
echo -e "\n${YELLOW}=== Database Tests ===${NC}"

run_test "PostgreSQL Connection" \
    "psql -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USER -d $DATABASE_NAME -c 'SELECT 1' 2>/dev/null" \
    "1"

run_test "Users Table Exists" \
    "psql -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USER -d $DATABASE_NAME -c '\\dt users' 2>/dev/null" \
    "users"

run_test "Sample Data Exists" \
    "psql -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USER -d $DATABASE_NAME -c 'SELECT COUNT(*) FROM users' 2>/dev/null" \
    "[0-9]"

run_test "Audit Log Table Exists" \
    "psql -h $DATABASE_HOST -p $DATABASE_PORT -U $DATABASE_USER -d $DATABASE_NAME -c '\\dt audit_logs' 2>/dev/null" \
    "audit_logs"

# Web Server 1 Tests
echo -e "\n${YELLOW}=== Web Server 1 Tests ($WEB_SERVER_1) ===${NC}"

run_test "Health Check" \
    "curl -s http://$WEB_SERVER_1/health" \
    "healthy"

run_test "Root Endpoint" \
    "curl -s http://$WEB_SERVER_1/" \
    "3-Tier Application API"

run_test "Users Endpoint (GET)" \
    "curl -s http://$WEB_SERVER_1/users | head -c 100" \
    "id"

run_test "Nginx Running" \
    "curl -s -o /dev/null -w '%{http_code}' http://$WEB_SERVER_1/" \
    "200"

# Web Server 2 Tests (if different from server 1)
if [ "$WEB_SERVER_2" != "$WEB_SERVER_1" ] && [ "$WEB_SERVER_2" != "localhost" ]; then
    echo -e "\n${YELLOW}=== Web Server 2 Tests ($WEB_SERVER_2) ===${NC}"
    
    run_test "Health Check" \
        "curl -s http://$WEB_SERVER_2/health" \
        "healthy"
    
    run_test "Root Endpoint" \
        "curl -s http://$WEB_SERVER_2/" \
        "3-Tier Application API"
    
    run_test "Users Endpoint (GET)" \
        "curl -s http://$WEB_SERVER_2/users | head -c 100" \
        "id"
    
    run_test "Nginx Running" \
        "curl -s -o /dev/null -w '%{http_code}' http://$WEB_SERVER_2/" \
        "200"
fi

# API Tests
echo -e "\n${YELLOW}=== API Tests ===${NC}"

run_test "GET /users" \
    "curl -s http://$WEB_SERVER_1/users" \
    "John"

run_test "Response Format JSON" \
    "curl -s http://$WEB_SERVER_1/users | head -c 1" \
    "\\["

run_test "Endpoint /products (if exists)" \
    "curl -s -o /dev/null -w '%{http_code}' http://$WEB_SERVER_1/products" \
    "[0-9]"

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total Tests: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ All tests passed! Application is running correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed. Please review the errors above.${NC}"
    exit 1
fi
