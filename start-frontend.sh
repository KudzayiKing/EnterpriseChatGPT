#!/bin/bash

cd frontend
nohup npm run dev > ../frontend.log 2>&1 &
echo $! > ../.frontend.pid
cd ..
echo "✅ Frontend started with PID $(cat .frontend.pid)"
echo "🌐 Frontend: http://localhost:3000"
echo "📝 Logs: tail -f frontend.log"
