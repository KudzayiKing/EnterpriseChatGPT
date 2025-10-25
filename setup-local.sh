#!/bin/bash

# Enterprise RAG 2.0 - Local Development Setup (No Docker)
# For macOS users who want to run without Docker

echo "🚀 Enterprise RAG 2.0 - Local Setup"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check Homebrew
echo "Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗ Homebrew is not installed${NC}"
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo -e "${GREEN}✓ Homebrew is installed${NC}"
echo ""

# Install Python
echo "Checking Python..."
if ! command -v python3 &> /dev/null; then
    echo "Installing Python 3.11..."
    brew install python@3.11
fi
echo -e "${GREEN}✓ Python is installed${NC}"
python3 --version
echo ""

# Install Node.js
echo "Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    brew install node@20
fi
echo -e "${GREEN}✓ Node.js is installed${NC}"
node --version
npm --version
echo ""

# Install PostgreSQL
echo "Checking PostgreSQL..."
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL..."
    brew install postgresql@15
    brew services start postgresql@15
fi
echo -e "${GREEN}✓ PostgreSQL is installed${NC}"
psql --version
echo ""

# Install Redis
echo "Checking Redis..."
if ! command -v redis-cli &> /dev/null; then
    echo "Installing Redis..."
    brew install redis
    brew services start redis
fi
echo -e "${GREEN}✓ Redis is installed${NC}"
redis-cli --version
echo ""

# Create database
echo "Setting up database..."
createdb enterprise_rag 2>/dev/null || echo "Database already exists"
echo -e "${GREEN}✓ Database ready${NC}"
echo ""

# Setup Backend
echo -e "${BLUE}=== Setting up Backend ===${NC}"
cd backend

# Create virtual environment
echo "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "Installing Python packages..."
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
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
else
    echo -e "${YELLOW}⚠ backend/.env already exists${NC}"
fi

# Create directories
mkdir -p uploads chroma_db logs

# Run migrations
echo "Running database migrations..."
alembic upgrade head

cd ..
echo -e "${GREEN}✓ Backend setup complete${NC}"
echo ""

# Setup Frontend
echo -e "${BLUE}=== Setting up Frontend ===${NC}"
cd frontend

# Install dependencies
echo "Installing Node.js packages..."
npm install

# Create .env.local file
if [ ! -f .env.local ]; then
    echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
    echo -e "${GREEN}✓ Created frontend/.env.local${NC}"
else
    echo -e "${YELLOW}⚠ frontend/.env.local already exists${NC}"
fi

cd ..
echo -e "${GREEN}✓ Frontend setup complete${NC}"
echo ""

# Create start script
cat > start-local.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting Enterprise RAG 2.0 (Local Mode)"
echo "==========================================="
echo ""

# Start backend
echo "Starting backend..."
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!
cd ..

# Wait a bit for backend to start
sleep 3

# Start frontend
echo "Starting frontend..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "✓ Services started!"
echo ""
echo "Frontend: http://localhost:3000"
echo "Backend: http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for Ctrl+C
trap "kill $BACKEND_PID $FRONTEND_PID; exit" INT
wait
EOF

chmod +x start-local.sh

# Create stop script
cat > stop-local.sh << 'EOF'
#!/bin/bash

echo "Stopping Enterprise RAG 2.0..."

# Kill backend
pkill -f "uvicorn app.main:app"

# Kill frontend
pkill -f "next dev"

echo "✓ Services stopped"
EOF

chmod +x stop-local.sh

echo "=================================="
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo ""
echo "⚠️  IMPORTANT: Edit backend/.env and add your OpenAI API key"
echo ""
echo "To start the application:"
echo "  ./start-local.sh"
echo ""
echo "To stop the application:"
echo "  ./stop-local.sh"
echo ""
echo "Services will be available at:"
echo "  Frontend: http://localhost:3000"
echo "  Backend: http://localhost:8000"
echo "  API Docs: http://localhost:8000/docs"
echo ""
