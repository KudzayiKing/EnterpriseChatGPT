#!/bin/bash

cd backend
source venv/bin/activate
nohup uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
echo $! > ../.backend.pid
cd ..
echo "✅ Backend started with PID $(cat .backend.pid)"
echo "📝 Logs: tail -f backend.log"
