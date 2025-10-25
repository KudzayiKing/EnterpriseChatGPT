#!/bin/bash

# Enterprise RAG 2.0 - API Testing Script
# This script tests all major API endpoints

echo "🧪 Enterprise RAG 2.0 API Testing"
echo "=================================="
echo ""

API_URL="http://localhost:8000"
TOKEN=""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Helper function to test endpoint
test_endpoint() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4
    local expected_code=$5
    
    echo -n "Testing: $name... "
    
    if [ "$method" = "GET" ]; then
        if [ -z "$TOKEN" ]; then
            response=$(curl -s -w "\n%{http_code}" -X GET "$API_URL$endpoint")
        else
            response=$(curl -s -w "\n%{http_code}" -X GET "$API_URL$endpoint" -H "Authorization: Bearer $TOKEN")
        fi
    elif [ "$method" = "POST" ]; then
        if [ -z "$TOKEN" ]; then
            response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL$endpoint" -H "Content-Type: application/json" -d "$data")
        else
            response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL$endpoint" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "$data")
        fi
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "$expected_code" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Expected $expected_code, got $http_code)"
        echo "Response: $body"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Check if API is running
echo "Checking if API is running..."
if ! curl -s "$API_URL/health" > /dev/null; then
    echo -e "${RED}✗ API is not running at $API_URL${NC}"
    echo "Please start the services with: docker-compose up -d"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"
echo ""

# Test 1: Health Check
echo "=== Basic Endpoints ==="
test_endpoint "Health Check" "GET" "/health" "" "200"
test_endpoint "Root Endpoint" "GET" "/" "" "200"
echo ""

# Test 2: User Registration
echo "=== Authentication ==="
RANDOM_USER="testuser_$(date +%s)"
REGISTER_DATA="{\"email\":\"$RANDOM_USER@example.com\",\"username\":\"$RANDOM_USER\",\"password\":\"testpass123\",\"full_name\":\"Test User\"}"

if test_endpoint "User Registration" "POST" "/api/v1/auth/register" "$REGISTER_DATA" "200"; then
    echo -e "${GREEN}✓ User created successfully${NC}"
else
    echo -e "${YELLOW}⚠ Using existing user for tests${NC}"
    RANDOM_USER="testuser"
fi

# Test 3: User Login
LOGIN_DATA="username=$RANDOM_USER&password=testpass123"
echo -n "Testing: User Login... "
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/auth/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "$LOGIN_DATA")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    TOKEN=$(echo "$body" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        echo -e "${GREEN}✓ Token obtained${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} (No token in response)"
        FAILED=$((FAILED + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} (Expected 200, got $http_code)"
    echo "Response: $body"
    FAILED=$((FAILED + 1))
fi

# Test 4: Get Current User
test_endpoint "Get Current User" "GET" "/api/v1/auth/me" "" "200"
echo ""

# Test 5: Chat Endpoints
echo "=== Chat Endpoints ==="
test_endpoint "Get Conversations" "GET" "/api/v1/chat/conversations" "" "200"

# Send a test message
MESSAGE_DATA='{"content":"Hello, this is a test message"}'
echo -n "Testing: Send Message... "
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/chat/message" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$MESSAGE_DATA")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    CONVERSATION_ID=$(echo "$body" | grep -o '"conversation_id":[0-9]*' | cut -d':' -f2)
    echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
    echo -e "${GREEN}✓ Conversation ID: $CONVERSATION_ID${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC} (Expected 200, got $http_code)"
    echo "Response: $body"
    FAILED=$((FAILED + 1))
fi

if [ -n "$CONVERSATION_ID" ]; then
    test_endpoint "Get Specific Conversation" "GET" "/api/v1/chat/conversations/$CONVERSATION_ID" "" "200"
fi
echo ""

# Test 6: Document Endpoints
echo "=== Document Endpoints ==="
test_endpoint "Get Documents" "GET" "/api/v1/documents/" "" "200"
echo ""

# Test 7: Analytics Endpoints
echo "=== Analytics Endpoints ==="
test_endpoint "Get Analytics Overview" "GET" "/api/v1/analytics/overview" "" "200"
test_endpoint "Get Usage Stats" "GET" "/api/v1/analytics/usage?days=7" "" "200"
echo ""

# Test 8: Error Handling
echo "=== Error Handling ==="
test_endpoint "Invalid Endpoint" "GET" "/api/v1/invalid" "" "404"
test_endpoint "Unauthorized Access" "GET" "/api/v1/chat/conversations" "" "401"
echo ""

# Summary
echo "=================================="
echo "Test Summary"
echo "=================================="
echo -e "Total Tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
