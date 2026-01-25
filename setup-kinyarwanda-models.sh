#!/bin/bash

# Setup script for Kinyarwanda-specific models
# This script downloads and configures:
# 1. AfriqueQwen-8B for generation (via Ollama)
# 2. KinyaColBERT for embeddings (via HuggingFace)

set -e

echo "=================================================="
echo "🇷🇼 Kinyarwanda Models Setup"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Ollama is running
echo -e "${BLUE}Checking Ollama...${NC}"
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Ollama is not running. Starting Ollama...${NC}"
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

# Download AfriqueQwen or fallback to Qwen2.5
echo ""
echo -e "${BLUE}📥 Downloading Kinyarwanda-capable LLM...${NC}"
echo "Trying AfriqueQwen-8B (African languages specific)..."

# Try to pull AfriqueQwen-8B from HuggingFace via Ollama
if ollama pull hf.co/McGill-NLP/AfriqueQwen-8B 2>/dev/null; then
    echo -e "${GREEN}✅ AfriqueQwen-8B downloaded${NC}"
    MODEL_NAME="hf.co/McGill-NLP/AfriqueQwen-8B"
else
    echo -e "${YELLOW}⚠️  AfriqueQwen-8B not available via Ollama${NC}"
    echo -e "${BLUE}Falling back to qwen2.5:7b (multilingual, good for Kinyarwanda)...${NC}"
    ollama pull qwen2.5:7b
    MODEL_NAME="qwen2.5:7b"
    echo -e "${GREEN}✅ qwen2.5:7b downloaded${NC}"
fi

echo ""
echo -e "${GREEN}✅ ${MODEL_NAME} downloaded successfully${NC}"

# Verify the model
echo ""
echo -e "${BLUE}Testing ${MODEL_NAME}...${NC}"
ollama run ${MODEL_NAME} "Muraho" --verbose=false || true

# Install Python dependencies for KinyaColBERT
echo ""
echo -e "${BLUE}📦 Installing Python dependencies for KinyaColBERT...${NC}"
cd backend
source venv/bin/activate 2>/dev/null || python3 -m venv venv && source venv/bin/activate

pip install --upgrade pip > /dev/null
pip install transformers torch sentence-transformers -q

# Pre-download KinyaColBERT model
echo ""
echo -e "${BLUE}📥 Pre-downloading KinyaColBERT embeddings model...${NC}"
python3 << EOF
from transformers import AutoTokenizer, AutoModel
import logging
logging.basicConfig(level=logging.INFO)

print("Downloading KinyaColBERT from HuggingFace...")
try:
    tokenizer = AutoTokenizer.from_pretrained("anzeyimana/KinyaColBERT", trust_remote_code=True)
    model = AutoModel.from_pretrained("anzeyimana/KinyaColBERT", trust_remote_code=True)
    print("✅ KinyaColBERT downloaded successfully")
except Exception as e:
    print(f"⚠️  KinyaColBERT not available, downloading fallback: jean-paul/KinyaBERT-large")
    tokenizer = AutoTokenizer.from_pretrained("jean-paul/KinyaBERT-large")
    model = AutoModel.from_pretrained("jean-paul/KinyaBERT-large")
    print("✅ KinyaBERT-large downloaded successfully (fallback)")
EOF

cd ..

echo ""
echo -e "${GREEN}=================================================="
echo "✅ Kinyarwanda Models Setup Complete!"
echo "==================================================${NC}"
echo ""
echo "Models installed:"
echo "  1. ${MODEL_NAME} (Generation) - Ollama"
echo "  2. KinyaColBERT (Embeddings) - HuggingFace"
echo ""
echo "Next steps:"
echo "  1. Update .env with the model name:"
echo "     ${YELLOW}OLLAMA_MODEL=${MODEL_NAME}${NC}"
echo ""
echo "  2. Clear ChromaDB to re-embed with KinyaColBERT:"
echo "     ${YELLOW}rm -rf backend/chroma_db${NC}"
echo ""
echo "  3. Restart backend:"
echo "     ${YELLOW}./kill-all.sh && ./dev.sh${NC}"
echo ""
echo "  4. Re-upload your Kinyarwanda documents in the UI"
echo ""
echo "  5. Test with Kinyarwanda queries!"
echo ""
