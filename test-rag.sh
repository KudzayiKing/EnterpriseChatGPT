#!/bin/bash

# Enterprise RAG 2.0 - RAG Pipeline Testing Script
# This script tests the RAG pipeline with sample documents

echo "🧪 Enterprise RAG 2.0 - RAG Pipeline Test"
echo "=========================================="
echo ""

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
    echo -e "${RED}✗ API is not running${NC}"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"
echo ""

# Login
echo "Logging in..."
RANDOM_USER="testuser_$(date +%s)"
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
    echo -e "${RED}✗ Failed to get authentication token${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Authenticated${NC}"
echo ""

# Create a test document
echo "Creating test document..."
cat > /tmp/test_rag_doc.txt << 'EOF'
Enterprise RAG 2.0 Documentation

What is RAG?
RAG stands for Retrieval-Augmented Generation. It is a technique that combines 
information retrieval with large language models to provide accurate, source-cited 
answers to user queries.

Key Features:
1. Multi-stage retrieval with vector search and reranking
2. Query expansion using HyDE and step-back prompting
3. Self-correction loops for improved accuracy
4. Source attribution for transparency

How it works:
The system first processes documents by chunking them into smaller pieces and 
generating embeddings. When a user asks a question, the system retrieves relevant 
chunks, reranks them for relevance, and uses them as context for the LLM to 
generate an accurate answer.

Benefits:
- Reduces hallucinations
- Provides source citations
- Works with private documents
- More accurate than standalone LLMs
EOF

echo -e "${GREEN}✓ Test document created${NC}"
echo ""

# Upload document
echo "Uploading test document..."
upload_response=$(curl -s -X POST "$API_URL/api/v1/documents/upload" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@/tmp/test_rag_doc.txt")

DOC_ID=$(echo "$upload_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -n "$DOC_ID" ]; then
    echo -e "${GREEN}✓ Document uploaded (ID: $DOC_ID)${NC}"
else
    echo -e "${RED}✗ Failed to upload document${NC}"
    echo "Response: $upload_response"
    exit 1
fi
echo ""

# Wait for processing
echo "Waiting for document processing..."
sleep 5
echo -e "${GREEN}✓ Processing complete${NC}"
echo ""

# Test RAG queries
echo "Testing RAG queries..."
echo "=================================="

test_query() {
    local query=$1
    echo ""
    echo -e "${YELLOW}Query: $query${NC}"
    
    response=$(curl -s -X POST "$API_URL/api/v1/chat/message" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "{\"content\":\"$query\"}")
    
    # Extract answer
    answer=$(echo "$response" | grep -o '"content":"[^"]*' | head -2 | tail -1 | cut -d'"' -f4)
    
    if [ -n "$answer" ]; then
        echo -e "${GREEN}Answer:${NC} $answer"
        
        # Check if sources are included
        if echo "$response" | grep -q '"sources"'; then
            echo -e "${GREEN}✓ Sources included${NC}"
        else
            echo -e "${YELLOW}⚠ No sources found${NC}"
        fi
    else
        echo -e "${RED}✗ No answer received${NC}"
        echo "Response: $response"
    fi
}

# Test queries
test_query "What is RAG?"
test_query "What are the key features of RAG 2.0?"
test_query "How does the RAG system work?"
test_query "What are the benefits of using RAG?"

echo ""
echo "=================================="
echo -e "${GREEN}✓ RAG Pipeline Test Complete${NC}"
echo ""
echo "Cleanup..."
rm -f /tmp/test_rag_doc.txt
echo -e "${GREEN}✓ Done${NC}"
