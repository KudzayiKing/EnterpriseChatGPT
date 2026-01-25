#!/bin/bash

# Test script to verify Kinyarwanda models are working

set -e

echo "=================================================="
echo "🧪 Testing Kinyarwanda Models"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test 1: Check Ollama is running
echo -e "${BLUE}Test 1: Checking Ollama...${NC}"
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama is running${NC}"
else
    echo -e "${RED}❌ Ollama is not running${NC}"
    echo "Start with: ollama serve"
    exit 1
fi

# Test 2: Check AfriqueQwen is downloaded
echo ""
echo -e "${BLUE}Test 2: Checking AfriqueQwen-8B...${NC}"
if ollama list | grep -q "AfriqueQwen"; then
    echo -e "${GREEN}✅ AfriqueQwen-8B is installed${NC}"
else
    echo -e "${RED}❌ AfriqueQwen-8B not found${NC}"
    echo "Download with: ollama pull mradermacher/AfriqueQwen-8B-i1-GGUF:latest"
    exit 1
fi

# Test 3: Test AfriqueQwen with Kinyarwanda
echo ""
echo -e "${BLUE}Test 3: Testing AfriqueQwen with Kinyarwanda...${NC}"
echo "Query: Muraho, witwa nde?"
RESPONSE=$(ollama run mradermacher/AfriqueQwen-8B-i1-GGUF:latest "Muraho, witwa nde?" 2>/dev/null | head -3)
if [ -n "$RESPONSE" ]; then
    echo -e "${GREEN}✅ AfriqueQwen responded${NC}"
    echo "Response: $RESPONSE"
else
    echo -e "${RED}❌ AfriqueQwen did not respond${NC}"
    exit 1
fi

# Test 4: Check Python dependencies
echo ""
echo -e "${BLUE}Test 4: Checking Python dependencies...${NC}"
cd backend
source venv/bin/activate 2>/dev/null || {
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
}

python3 << EOF
try:
    import transformers
    import torch
    import sentence_transformers
    print("${GREEN}✅ All Python dependencies installed${NC}")
except ImportError as e:
    print(f"${RED}❌ Missing dependency: {e}${NC}")
    exit(1)
EOF

# Test 5: Test KinyaColBERT loading
echo ""
echo -e "${BLUE}Test 5: Testing KinyaColBERT loading...${NC}"
python3 << EOF
import sys
sys.path.insert(0, '.')
try:
    from app.core.kinyacolbert_embeddings import KinyaColBERTEmbeddings
    embeddings = KinyaColBERTEmbeddings()
    test_text = "Kwandikisha ubutaka"
    embedding = embeddings.embed_query(test_text)
    print("${GREEN}✅ KinyaColBERT loaded and working${NC}")
    print(f"Embedding dimension: {len(embedding)}")
except Exception as e:
    print(f"${RED}❌ KinyaColBERT error: {e}${NC}")
    exit(1)
EOF

cd ..

# Test 6: Check backend configuration
echo ""
echo -e "${BLUE}Test 6: Checking backend configuration...${NC}"
if grep -q "AfriqueQwen" backend/.env; then
    echo -e "${GREEN}✅ .env configured for AfriqueQwen${NC}"
else
    echo -e "${YELLOW}⚠️  .env not configured for AfriqueQwen${NC}"
fi

if grep -q "USE_KINYACOLBERT=true" backend/.env; then
    echo -e "${GREEN}✅ .env configured for KinyaColBERT${NC}"
else
    echo -e "${YELLOW}⚠️  .env not configured for KinyaColBERT${NC}"
fi

# Test 7: Check ChromaDB status
echo ""
echo -e "${BLUE}Test 7: Checking ChromaDB...${NC}"
if [ -d "backend/chroma_db" ]; then
    CHUNK_COUNT=$(find backend/chroma_db -type f | wc -l)
    if [ "$CHUNK_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ ChromaDB exists with data${NC}"
        echo "Files: $CHUNK_COUNT"
    else
        echo -e "${YELLOW}⚠️  ChromaDB exists but empty - upload documents${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  ChromaDB not found - will be created on first upload${NC}"
fi

# Test 8: Check backend is running
echo ""
echo -e "${BLUE}Test 8: Checking backend...${NC}"
if curl -s http://localhost:8000/docs > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${YELLOW}⚠️  Backend is not running${NC}"
    echo "Start with: ./dev.sh"
fi

echo ""
echo -e "${GREEN}=================================================="
echo "✅ All Tests Passed!"
echo "==================================================${NC}"
echo ""
echo "Your system is ready for Kinyarwanda RAG!"
echo ""
echo "Next steps:"
echo "  1. Make sure backend is running: ${YELLOW}./dev.sh${NC}"
echo "  2. Upload Kinyarwanda documents in the UI"
echo "  3. Test with queries like:"
echo "     - Ni iki gikenewe kugira ngo nandikishe ubutaka?"
echo "     - Ni gute nabona pasiporo?"
echo ""
