#!/bin/bash

# Verify RAG Fix Script
# This script checks if the RAG system is working correctly

echo "=========================================="
echo "RAG System Fix Verification"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Files exist
echo "1. Checking if fix files exist..."
if [ -f "backend/app/core/rag_orchestrator_local.py" ]; then
    echo -e "${GREEN}✓${NC} rag_orchestrator_local.py exists"
else
    echo -e "${RED}✗${NC} rag_orchestrator_local.py not found"
    exit 1
fi

# Check 2: Methods exist
echo ""
echo "2. Checking if new methods exist..."

if grep -q "_preprocess_query" backend/app/core/rag_orchestrator_local.py; then
    echo -e "${GREEN}✓${NC} _preprocess_query() method found"
else
    echo -e "${RED}✗${NC} _preprocess_query() method not found"
    exit 1
fi

if grep -q "_filter_relevant_chunks" backend/app/core/rag_orchestrator_local.py; then
    echo -e "${GREEN}✓${NC} _filter_relevant_chunks() method found"
else
    echo -e "${RED}✗${NC} _filter_relevant_chunks() method not found"
    exit 1
fi

if grep -q "_clean_answer" backend/app/core/rag_orchestrator_local.py; then
    echo -e "${GREEN}✓${NC} _clean_answer() method found"
else
    echo -e "${RED}✗${NC} _clean_answer() method not found"
    exit 1
fi

# Check 3: Ollama is running
echo ""
echo "3. Checking if Ollama is running..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Ollama is running"
else
    echo -e "${YELLOW}⚠${NC} Ollama is not running (start with: ollama serve)"
fi

# Check 4: ChromaDB exists
echo ""
echo "4. Checking if ChromaDB exists..."
if [ -d "chroma_db" ]; then
    echo -e "${GREEN}✓${NC} ChromaDB directory exists"
    COLLECTIONS=$(ls -1 chroma_db/ 2>/dev/null | wc -l)
    echo "   Found $COLLECTIONS collection(s)"
else
    echo -e "${YELLOW}⚠${NC} ChromaDB directory not found (documents not indexed yet)"
fi

# Check 5: Test script exists
echo ""
echo "5. Checking test script..."
if [ -f "test_rag_query.py" ]; then
    echo -e "${GREEN}✓${NC} test_rag_query.py exists"
else
    echo -e "${RED}✗${NC} test_rag_query.py not found"
fi

# Check 6: Python dependencies
echo ""
echo "6. Checking Python dependencies..."
cd backend
if python -c "import sentence_transformers" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} sentence-transformers installed"
else
    echo -e "${RED}✗${NC} sentence-transformers not installed"
    echo "   Install with: pip install sentence-transformers"
fi

if python -c "import chromadb" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} chromadb installed"
else
    echo -e "${RED}✗${NC} chromadb not installed"
    echo "   Install with: pip install chromadb"
fi
cd ..

# Summary
echo ""
echo "=========================================="
echo "Verification Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. If Ollama is not running: ollama serve"
echo "2. If documents not indexed: ./reindex-documents.sh"
echo "3. Test the fix: python test_rag_query.py"
echo "4. Start backend: cd backend && uvicorn app.main:app --reload"
echo ""
echo "For more info, see:"
echo "- QUICK_FIX_GUIDE.md"
echo "- RAG_FIX_SUMMARY.md"
echo "- TEST_RAG_QUERIES.md"
