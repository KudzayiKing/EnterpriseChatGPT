#!/bin/bash

# Simplified setup script with better error handling

echo "🚀 Enterprise RAG 2.0 - Simplified Setup"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fix npm cache permissions first
echo "Fixing npm cache permissions..."
sudo chown -R $(whoami) "/Users/$(whoami)/.npm-cache" 2>/dev/null || true
echo ""

# Backend setup
echo "=== Setting up Backend ==="
cd backend

# Create virtual environment
echo "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip setuptools wheel

# Install dependencies one by one for better error handling
echo "Installing Python packages (this may take a few minutes)..."
pip install fastapi uvicorn sqlalchemy psycopg2-binary alembic redis python-dotenv
pip install langchain langchain-openai openai sentence-transformers chromadb
pip install pypdf2 python-docx python-pptx openpyxl beautifulsoup4
pip install python-multipart python-jose passlib bcrypt pydantic pydantic-settings
pip install httpx aiofiles

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    cat > .env << EOF
DATABASE_URL=postgresql://$(whoami)@localhost:5432/enterprise_rag
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=your_openai_api_key_here
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
ENVIRONMENT=development
DEBUG=True
CORS_ORIGINS=http://localhost:3000
MAX_UPLOAD_SIZE=52428800
UPLOAD_DIR=./uploads
CHROMA_PERSIST_DIR=./chroma_db
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
CHUNK_SIZE=512
CHUNK_OVERLAP=50
TOP_K_RETRIEVAL=10
RERANK_TOP_K=5
EOF
    echo -e "${GREEN}✓ Created backend/.env${NC}"
fi

# Create directories
mkdir -p uploads chroma_db logs

# Initialize alembic if needed
if [ ! -d "alembic/versions" ]; then
    echo "Initializing database migrations..."
    alembic init alembic 2>/dev/null || true
fi

# Try to run migrations (may fail if DB not ready, that's ok)
echo "Attempting database migrations..."
alembic upgrade head 2>/dev/null || echo "Migrations will run on first start"

cd ..
echo -e "${GREEN}✓ Backend setup complete${NC}"
echo ""

# Frontend setup
echo "=== Setting up Frontend ==="
cd frontend

# Fix permissions
sudo chown -R $(whoami) . 2>/dev/null || true

# Install dependencies
echo "Installing Node.js packages..."
npm install --legacy-peer-deps

# Create .env.local
if [ ! -f .env.local ]; then
    echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
    echo -e "${GREEN}✓ Created frontend/.env.local${NC}"
fi

cd ..
echo -e "${GREEN}✓ Frontend setup complete${NC}"
echo ""

# Create improved start script
cat > start-local.sh << 'STARTSCRIPT'
#!/bin/bash

echo "🚀 Starting Enterprise RAG 2.0"
echo "=============================="
echo ""

# Check if PostgreSQL is running
if ! pg_isready -q 2>/dev/null; then
    echo "Starting PostgreSQL..."
    brew services start postgresql@15
    sleep 2
fi

# Check if Redis is running
if ! redis-cli ping > /dev/null 2>&1; then
    echo "Starting Redis..."
    brew services start redis
    sleep 1
fi

# Start backend
echo "Starting backend on http://localhost:8000"
cd backend
source venv/bin/activate

# Run migrations
alembic upgrade head 2>/dev/null || true

# Start backend in background
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"
cd ..

# Wait for backend to start
echo "Waiting for backend to start..."
sleep 5

# Start frontend
echo "Starting frontend on http://localhost:3000"
cd frontend
npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend PID: $FRONTEND_PID"
cd ..

echo ""
echo "✓ Services started!"
echo ""
echo "Frontend: http://localhost:3000"
echo "Backend:  http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
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

chmod +x start-local.sh

# Create improved stop script
cat > stop-local.sh << 'STOPSCRIPT'
#!/bin/bash

echo "Stopping Enterprise RAG 2.0..."

# Kill by PID if available
if [ -f .backend.pid ]; then
    kill $(cat .backend.pid) 2>/dev/null
    rm .backend.pid
fi

if [ -f .frontend.pid ]; then
    kill $(cat .frontend.pid) 2>/dev/null
    rm .frontend.pid
fi

# Kill by process name as backup
pkill -f "uvicorn app.main:app" 2>/dev/null
pkill -f "next dev" 2>/dev/null

echo "✓ Services stopped"
STOPSCRIPT

chmod +x stop-local.sh

echo "=================================="
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
echo ""
echo "1. Add your OpenAI API key:"
echo "   nano backend/.env"
echo "   (Change OPENAI_API_KEY=your_openai_api_key_here)"
echo ""
echo "2. Start the application:"
echo "   ./start-local.sh"
echo ""
echo "3. Open in browser:"
echo "   open http://localhost:3000"
echo ""
