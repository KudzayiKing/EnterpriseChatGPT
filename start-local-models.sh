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
