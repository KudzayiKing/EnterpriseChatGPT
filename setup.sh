#!/bin/bash

echo "🚀 Enterprise RAG 2.0 Setup Script"
echo "=================================="

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Setup environment files
echo ""
echo "Setting up environment files..."

if [ ! -f .env ]; then
    cp .env.example .env 2>/dev/null || echo "DATABASE_URL=postgresql://postgres:postgres@postgres:5432/enterprise_rag
REDIS_URL=redis://redis:6379
OPENAI_API_KEY=your_openai_api_key_here
SECRET_KEY=$(openssl rand -hex 32)
CORS_ORIGINS=http://localhost:3000" > .env
    echo "✅ Created .env file"
    echo "⚠️  Please edit .env and add your OPENAI_API_KEY"
else
    echo "ℹ️  .env file already exists"
fi

if [ ! -f backend/.env ]; then
    cp backend/.env.example backend/.env 2>/dev/null || echo "DATABASE_URL=postgresql://postgres:postgres@postgres:5432/enterprise_rag
REDIS_URL=redis://redis:6379
OPENAI_API_KEY=your_openai_api_key_here
SECRET_KEY=$(openssl rand -hex 32)" > backend/.env
    echo "✅ Created backend/.env file"
fi

if [ ! -f frontend/.env.local ]; then
    cp frontend/.env.local.example frontend/.env.local 2>/dev/null || echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > frontend/.env.local
    echo "✅ Created frontend/.env.local file"
fi

# Create necessary directories
echo ""
echo "Creating directories..."
mkdir -p backend/uploads backend/chroma_db backend/logs
mkdir -p frontend/.next
echo "✅ Directories created"

# Start services
echo ""
echo "Starting services with Docker Compose..."
docker-compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 10

# Check service health
echo ""
echo "Checking service health..."

if docker-compose ps | grep -q "postgres.*Up"; then
    echo "✅ PostgreSQL is running"
else
    echo "❌ PostgreSQL failed to start"
fi

if docker-compose ps | grep -q "redis.*Up"; then
    echo "✅ Redis is running"
else
    echo "❌ Redis failed to start"
fi

echo ""
echo "=================================="
echo "🎉 Setup Complete!"
echo ""
echo "Services:"
echo "  - Frontend: http://localhost:3000"
echo "  - Backend API: http://localhost:8000"
echo "  - API Docs: http://localhost:8000/docs"
echo ""
echo "Next steps:"
echo "  1. Edit .env and add your OPENAI_API_KEY"
echo "  2. Restart services: docker-compose restart"
echo "  3. Open http://localhost:3000 in your browser"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo ""
