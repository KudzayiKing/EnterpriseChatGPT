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
