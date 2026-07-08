#!/bin/bash

# Cleanup Script - Deletes all AWS resources created by the deployment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

STACK_NAME="${STACK_NAME:-3-tier-app-stack}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo -e "${RED}========================================${NC}"
echo -e "${RED}⚠️  WARNING: This will delete all resources!${NC}"
echo -e "${RED}========================================${NC}"
echo -e "\nStack Name: ${STACK_NAME}"
echo -e "Region: ${AWS_REGION}"
echo -e "\nThis action cannot be undone!"

read -p "Type 'yes' to confirm deletion: " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Deleting CloudFormation stack...${NC}"

if aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --region "${AWS_REGION}" > /dev/null 2>&1; then
    
    aws cloudformation delete-stack \
        --stack-name "${STACK_NAME}" \
        --region "${AWS_REGION}"
    
    echo -e "${YELLOW}Waiting for stack deletion...${NC}"
    aws cloudformation wait stack-delete-complete \
        --stack-name "${STACK_NAME}" \
        --region "${AWS_REGION}"
    
    echo -e "${GREEN}✓ Stack deleted successfully${NC}"
else
    echo -e "${YELLOW}Stack not found${NC}"
fi

echo -e "${GREEN}Cleanup complete!${NC}"
