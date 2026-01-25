#!/bin/bash

echo "🛑 Killing all processes..."

# Kill backend
ps aux | grep "uvicorn app.main:app" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null

# Kill frontend on all ports
lsof -ti:3000 -ti:3003 | xargs kill -9 2>/dev/null

# Kill any node processes related to Next.js
ps aux | grep "next dev" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null

# Clean PID files
rm -f .backend.pid .frontend.pid

echo "✅ All processes killed"
