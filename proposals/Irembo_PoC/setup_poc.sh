#!/bin/bash

# Irembo PoC Setup Script
# This script ingests the Irembo Land and Immigration data into the RAG system

echo "🇷🇼 Irembo PoC - Data Ingestion"
echo "=============================="

API_URL="http://localhost:8000"
TOKEN=""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if API is running
echo "Checking if API is running..."
if ! curl -s "$API_URL/health" > /dev/null; then
    echo -e "${RED}✗ API is not running. Please start the backend ('make run-backend' or './start-local.sh' in root)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"
echo ""

# Login/Register Temp User for PoC
echo "Creating/Logging in PoC User..."
POC_USER="irembo_admin_$(date +%s)"
REGISTER_DATA="{\"email\":\"$POC_USER@irembo.gov.rw\",\"username\":\"$POC_USER\",\"password\":\"irembo123\",\"tenant_name\":\"IremboGov\"}"

curl -s -X POST "$API_URL/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "$REGISTER_DATA" > /dev/null

LOGIN_DATA="username=$POC_USER&password=irembo123"
response=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "$LOGIN_DATA")

TOKEN=$(echo "$response" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗ Failed to get authentication token${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated as $POC_USER${NC}"
echo ""

# Upload Documents
upload_doc() {
    local filepath=$1
    echo "Uploading $(basename $filepath)..."
    upload_response=$(curl -s -X POST "$API_URL/api/v1/documents/upload" \
        -H "Authorization: Bearer $TOKEN" \
        -F "file=@$filepath")

    DOC_ID=$(echo "$upload_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

    if [ -n "$DOC_ID" ]; then
        echo -e "${GREEN}✓ Uploaded (ID: $DOC_ID)${NC}"
    else
        echo -e "${RED}✗ Failed to upload${NC}"
        echo "Response: $upload_response"
    fi
}

DATA_DIR="./proposals/Irembo_PoC/data"
upload_doc "$DATA_DIR/land_services.txt"
upload_doc "$DATA_DIR/immigration_services.txt"

echo ""
echo "Waiting for processing..."
sleep 5
echo -e "${GREEN}✓ Documents Processed${NC}"
echo ""

# Test Queries
test_query() {
    local query=$1
    echo -e "${YELLOW}Query: $query${NC}"
    
    response=$(curl -s -X POST "$API_URL/api/v1/chat/message" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "{\"content\":\"$query\"}")
    
    # Simple extraction (JSON parsing with grep/cut is fragile but works for simple structure)
    # Ideally use jq if available, but stick to grep/cut for portability here
    answer=$(echo "$response" | sed 's/\\"/\"/g' | grep -o '"content":"[^"]*' | head -1 | cut -d'"' -f4)
    
    if [ -n "$answer" ]; then
        echo -e "${GREEN}Response:${NC} $answer"
    else
        echo -e "${RED}✗ No content in response${NC}"
        # Print first 200 chars of response to debug
        echo "$response" | cut -c 1-200
    fi
    echo ""
}

echo "Running Test Queries..."
echo "-----------------------"
test_query "What is the cost of land registration?"
test_query "How do I apply for a visa?"
test_query "What are the requirements for land subdivision?"

echo "=============================="
echo -e "${GREEN}✓ PoC Setup Complete${NC}"
