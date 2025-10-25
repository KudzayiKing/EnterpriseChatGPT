#!/bin/bash

echo "🔍 Checking Backend Status..."
echo ""

# Check if backend is running
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend is running!"
    echo ""
    echo "Backend: http://localhost:8000"
    echo "API Docs: http://localhost:8000/docs"
    echo ""
else
    echo "❌ Backend is NOT running"
    echo ""
    echo "Starting backend now..."
    echo ""
    
    cd backend
    source venv/bin/activate
    
    # Check if database is ready
    if ! pg_isready -q 2>/dev/null; then
        echo "Starting PostgreSQL..."
        brew services start postgresql@15
        sleep 2
    fi
    
    # Check if Redis is ready
    if ! redis-cli ping > /dev/null 2>&1; then
        echo "Starting Redis..."
        brew services start redis
        sleep 1
    fi
    
    # Run migrations
    echo "Running migrations..."
    alembic upgrade head 2>/dev/null || true
    
    # Start backend
    echo "Starting backend server..."
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > ../.backend.pid
    
    cd ..
    
    echo ""
    echo "Waiting for backend to start..."
    sleep 5
    
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ Backend started successfully!"
        echo ""
        echo "Backend: http://localhost:8000"
        echo "API Docs: http://localhost:8000/docs"
        echo "PID: $BACKEND_PID"
        echo ""
        echo "View logs: tail -f backend.log"
    else
        echo "❌ Backend failed to start"
        echo "Check logs: tail -f backend.log"
    fi
fi
