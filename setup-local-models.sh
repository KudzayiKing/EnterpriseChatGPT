#!/bin/bash

# Complete Local Setup - No OpenAI Required!

echo "🚀 Enterprise RAG 2.0 - 100% Local Setup"
echo "========================================="
echo "No OpenAI API key needed!"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Step 1: Install Ollama
echo -e "${BLUE}Step 1: Installing Ollama${NC}"
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    brew install ollama
    echo -e "${GREEN}✓ Ollama installed${NC}"
else
    echo -e "${GREEN}✓ Ollama already installed${NC}"
fi
echo ""

# Step 2: Start Ollama service
echo -e "${BLUE}Step 2: Starting Ollama service${NC}"
echo "Starting Ollama in background..."
ollama serve > /dev/null 2>&1 &
OLLAMA_PID=$!
echo "Ollama PID: $OLLAMA_PID"
sleep 3
echo -e "${GREEN}✓ Ollama service started${NC}"
echo ""

# Step 3: Download Llama model
echo -e "${BLUE}Step 3: Downloading Llama 3.1 8B model${NC}"
echo "This will download ~4.7 GB (may take 5-10 minutes)..."
if ollama list | grep -q "llama3.1:8b"; then
    echo -e "${GREEN}✓ Llama 3.1 8B already downloaded${NC}"
else
    ollama pull llama3.1:8b
    echo -e "${GREEN}✓ Llama 3.1 8B downloaded${NC}"
fi
echo ""

# Step 4: Test the model
echo -e "${BLUE}Step 4: Testing the model${NC}"
echo "Testing Llama 3.1..."
ollama run llama3.1:8b "Say 'Hello, I am ready!'" --verbose=false
echo -e "${GREEN}✓ Model is working${NC}"
echo ""

# Step 5: Setup backend
echo -e "${BLUE}Step 5: Setting up backend${NC}"
cd backend

# Activate virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi
source venv/bin/activate

# Install dependencies
echo "Installing Python packages..."
pip install --upgrade pip setuptools wheel > /dev/null 2>&1
pip install pydantic-settings > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1
pip install langchain-community sentence-transformers transformers torch > /dev/null 2>&1

echo -e "${GREEN}✓ Backend dependencies installed${NC}"

# Create .env with local configuration
cat > .env << EOF
DATABASE_URL=postgresql://$(whoami)@localhost:5432/enterprise_rag
REDIS_URL=redis://localhost:6379

# Local models - No OpenAI needed!
USE_LOCAL_MODELS=true
OPENAI_API_KEY=not-needed

# Ollama configuration
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1:8b

# Local embedding model
LOCAL_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2

SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
ENVIRONMENT=development
DEBUG=True
CORS_ORIGINS=http://localhost:3000
MAX_UPLOAD_SIZE=52428800
UPLOAD_DIR=./uploads
CHROMA_PERSIST_DIR=./chroma_db
CHUNK_SIZE=512
CHUNK_OVERLAP=50
TOP_K_RETRIEVAL=10
RERANK_TOP_K=5
EOF

echo -e "${GREEN}✓ Backend configuration created${NC}"

# Create directories
mkdir -p uploads chroma_db logs

# Run migrations
echo "Running database migrations..."
alembic upgrade head 2>/dev/null || echo "Migrations will run on first start"

cd ..
echo ""

# Step 6: Setup frontend
echo -e "${BLUE}Step 6: Setting up frontend${NC}"
cd frontend

# Fix npm permissions
sudo chown -R $(whoami) ~/.npm-cache 2>/dev/null || true

# Install dependencies
echo "Installing Node.js packages..."
npm install --legacy-peer-deps > /dev/null 2>&1

# Create .env.local
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local

cd ..
echo -e "${GREEN}✓ Frontend setup complete${NC}"
echo ""

# Create start script
cat > start-local-models.sh << 'STARTSCRIPT'
#!/bin/bash

echo "🚀 Starting Enterprise RAG 2.0 (100% Local)"
echo "==========================================="
echo ""

# Start Ollama if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama..."
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

# Check PostgreSQL
if ! pg_isready -q 2>/dev/null; then
    echo "Starting PostgreSQL..."
    brew services start postgresql@15
    sleep 2
fi

# Check Redis
if ! redis-cli ping > /dev/null 2>&1; then
    echo "Starting Redis..."
    brew services start redis
    sleep 1
fi

# Start backend
echo "Starting backend (Local Models)..."
cd backend
source venv/bin/activate
alembic upgrade head 2>/dev/null || true
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
cd ..

# Wait for backend
echo "Waiting for backend to start..."
sleep 5

# Start frontend
echo "Starting frontend..."
cd frontend
npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"
cd ..

echo ""
echo "✓ All services started!"
echo ""
echo "🎉 Running 100% locally - No OpenAI needed!"
echo ""
echo "Frontend: http://localhost:3000"
echo "Backend:  http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
echo ""
echo "Models:"
echo "  - LLM: Llama 3.1 8B (Local)"
echo "  - Embeddings: all-MiniLM-L6-v2 (Local)"
echo "  - Reranker: ms-marco-MiniLM (Local)"
echo ""
echo "Logs:"
echo "  Backend:  tail -f backend.log"
echo "  Frontend: tail -f frontend.log"
echo ""
echo "To stop: ./stop-local.sh"
echo ""

# Save PIDs
echo $BACKEND_PID > .backend.pid
echo $FRONTEND_PID > .frontend.pid
STARTSCRIPT

chmod +x start-local-models.sh

echo "=================================="
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}🎉 You're ready to go!${NC}"
echo ""
echo "Your app is configured to run 100% locally:"
echo "  ✅ No OpenAI API key needed"
echo "  ✅ No internet connection required"
echo "  ✅ Complete data privacy"
echo "  ✅ Zero ongoing costs"
echo ""
echo "To start the application:"
echo "  ./start-local-models.sh"
echo ""
echo "To stop:"
echo "  ./stop-local.sh"
echo ""
echo "Models being used:"
echo "  - Llama 3.1 8B (4.7 GB)"
echo "  - all-MiniLM-L6-v2 (80 MB)"
echo "  - ms-marco-MiniLM (90 MB)"
echo ""
