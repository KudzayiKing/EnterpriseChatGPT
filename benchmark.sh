#!/bin/bash

# Enterprise RAG 2.0 - Benchmark Script
# Performance testing and benchmarking

echo "⚡ Enterprise RAG 2.0 - Benchmark Suite"
echo "========================================"
echo ""

API_URL="http://localhost:8000"
TOKEN=""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if API is running
if ! curl -s "$API_URL/health" > /dev/null; then
    echo -e "${RED}✗ API is not running${NC}"
    exit 1
fi

# Setup - Create user and login
echo "Setting up test user..."
RANDOM_USER="benchmark_$(date +%s)"
REGISTER_DATA="{\"email\":\"$RANDOM_USER@example.com\",\"username\":\"$RANDOM_USER\",\"password\":\"testpass123\"}"

curl -s -X POST "$API_URL/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "$REGISTER_DATA" > /dev/null

LOGIN_DATA="username=$RANDOM_USER&password=testpass123"
response=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "$LOGIN_DATA")

TOKEN=$(echo "$response" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗ Failed to authenticate${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Test user ready${NC}"
echo ""

# Benchmark 1: API Response Times
echo -e "${BLUE}=== Benchmark 1: API Response Times ===${NC}"
echo ""

benchmark_endpoint() {
    local name=$1
    local method=$2
    local endpoint=$3
    local iterations=10
    
    echo -n "Testing $name ($iterations requests)... "
    
    total_time=0
    for i in $(seq 1 $iterations); do
        if [ "$method" = "GET" ]; then
            time=$(curl -o /dev/null -s -w '%{time_total}' \
                -H "Authorization: Bearer $TOKEN" \
                "$API_URL$endpoint")
        else
            time=$(curl -o /dev/null -s -w '%{time_total}' \
                -X POST \
                -H "Authorization: Bearer $TOKEN" \
                -H "Content-Type: application/json" \
                -d '{"content":"test"}' \
                "$API_URL$endpoint")
        fi
        total_time=$(echo "$total_time + $time" | bc)
    done
    
    avg_time=$(echo "scale=3; $total_time / $iterations" | bc)
    echo -e "${GREEN}Avg: ${avg_time}s${NC}"
}

benchmark_endpoint "Health Check" "GET" "/health"
benchmark_endpoint "Get Conversations" "GET" "/api/v1/chat/conversations"
benchmark_endpoint "Get Documents" "GET" "/api/v1/documents/"
benchmark_endpoint "Analytics Overview" "GET" "/api/v1/analytics/overview"
echo ""

# Benchmark 2: Concurrent Requests
echo -e "${BLUE}=== Benchmark 2: Concurrent Requests ===${NC}"
echo ""

concurrent_test() {
    local concurrent=$1
    local total_requests=$2
    
    echo "Testing with $concurrent concurrent requests ($total_requests total)..."
    
    start_time=$(date +%s.%N)
    
    for i in $(seq 1 $total_requests); do
        curl -s -o /dev/null \
            -H "Authorization: Bearer $TOKEN" \
            "$API_URL/api/v1/chat/conversations" &
        
        if [ $((i % concurrent)) -eq 0 ]; then
            wait
        fi
    done
    wait
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    rps=$(echo "scale=2; $total_requests / $duration" | bc)
    
    echo -e "${GREEN}Duration: ${duration}s${NC}"
    echo -e "${GREEN}Requests/sec: ${rps}${NC}"
    echo ""
}

concurrent_test 5 50
concurrent_test 10 100

# Benchmark 3: Document Processing
echo -e "${BLUE}=== Benchmark 3: Document Processing ===${NC}"
echo ""

# Create test documents of different sizes
create_test_doc() {
    local size=$1
    local filename="/tmp/test_doc_${size}.txt"
    
    echo "Creating ${size} test document..."
    head -c ${size} /dev/urandom | base64 > "$filename"
    echo "$filename"
}

benchmark_upload() {
    local size=$1
    local filename=$(create_test_doc $size)
    
    echo -n "Uploading ${size} document... "
    
    start_time=$(date +%s.%N)
    
    response=$(curl -s -X POST "$API_URL/api/v1/documents/upload" \
        -H "Authorization: Bearer $TOKEN" \
        -F "file=@$filename")
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    if echo "$response" | grep -q '"id"'; then
        echo -e "${GREEN}Success in ${duration}s${NC}"
    else
        echo -e "${RED}Failed${NC}"
    fi
    
    rm -f "$filename"
}

benchmark_upload "1K"
benchmark_upload "10K"
benchmark_upload "100K"
echo ""

# Benchmark 4: Chat Response Times
echo -e "${BLUE}=== Benchmark 4: Chat Response Times ===${NC}"
echo ""

benchmark_chat() {
    local query=$1
    
    echo -n "Query: '$query'... "
    
    start_time=$(date +%s.%N)
    
    response=$(curl -s -X POST "$API_URL/api/v1/chat/message" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "{\"content\":\"$query\"}")
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    if echo "$response" | grep -q '"content"'; then
        echo -e "${GREEN}Response in ${duration}s${NC}"
    else
        echo -e "${RED}Failed${NC}"
    fi
}

benchmark_chat "Hello"
benchmark_chat "What is RAG?"
benchmark_chat "Explain the benefits of using retrieval-augmented generation"
echo ""

# Benchmark 5: Memory Usage
echo -e "${BLUE}=== Benchmark 5: Resource Usage ===${NC}"
echo ""

echo "Current resource usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo ""

# Summary
echo "========================================"
echo -e "${GREEN}✓ Benchmark Complete${NC}"
echo ""
echo "Tips for optimization:"
echo "  - Enable Redis caching for better performance"
echo "  - Use connection pooling for database"
echo "  - Consider horizontal scaling for high load"
echo "  - Monitor and optimize slow queries"
echo ""
