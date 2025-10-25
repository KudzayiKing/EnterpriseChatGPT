#!/bin/bash

# Enterprise RAG 2.0 - Development Helper Script
# Quick commands for common development tasks

command=$1

case $command in
    start)
        echo "🚀 Starting all services..."
        docker-compose up -d
        echo "✓ Services started"
        echo ""
        echo "Frontend: http://localhost:3000"
        echo "Backend: http://localhost:8000"
        echo "API Docs: http://localhost:8000/docs"
        ;;
    
    stop)
        echo "🛑 Stopping all services..."
        docker-compose down
        echo "✓ Services stopped"
        ;;
    
    restart)
        echo "🔄 Restarting all services..."
        docker-compose restart
        echo "✓ Services restarted"
        ;;
    
    logs)
        service=${2:-""}
        if [ -z "$service" ]; then
            docker-compose logs -f
        else
            docker-compose logs -f $service
        fi
        ;;
    
    status)
        echo "📊 Service Status"
        echo "================="
        docker-compose ps
        ;;
    
    clean)
        echo "🧹 Cleaning up..."
        docker-compose down -v
        rm -rf backend/uploads/* backend/chroma_db/* backend/logs/*
        echo "✓ Cleanup complete"
        ;;
    
    reset)
        echo "🔄 Resetting everything..."
        docker-compose down -v
        rm -rf backend/uploads/* backend/chroma_db/* backend/logs/*
        docker-compose up -d
        echo "✓ Reset complete"
        ;;
    
    test)
        echo "🧪 Running tests..."
        ./test-api.sh
        ;;
    
    test-rag)
        echo "🧪 Running RAG tests..."
        ./test-rag.sh
        ;;
    
    shell-backend)
        echo "🐚 Opening backend shell..."
        docker-compose exec backend bash
        ;;
    
    shell-frontend)
        echo "🐚 Opening frontend shell..."
        docker-compose exec frontend sh
        ;;
    
    shell-db)
        echo "🐚 Opening database shell..."
        docker-compose exec postgres psql -U postgres -d enterprise_rag
        ;;
    
    migrate)
        echo "🔄 Running database migrations..."
        docker-compose exec backend alembic upgrade head
        echo "✓ Migrations complete"
        ;;
    
    backup)
        echo "💾 Creating backup..."
        timestamp=$(date +%Y%m%d_%H%M%S)
        docker-compose exec postgres pg_dump -U postgres enterprise_rag > backup_$timestamp.sql
        tar -czf backup_$timestamp.tar.gz backend/chroma_db/
        echo "✓ Backup created: backup_$timestamp.sql and backup_$timestamp.tar.gz"
        ;;
    
    help|*)
        echo "Enterprise RAG 2.0 - Development Helper"
        echo "======================================="
        echo ""
        echo "Usage: ./dev.sh [command]"
        echo ""
        echo "Commands:"
        echo "  start          - Start all services"
        echo "  stop           - Stop all services"
        echo "  restart        - Restart all services"
        echo "  logs [service] - View logs (optionally for specific service)"
        echo "  status         - Show service status"
        echo "  clean          - Clean up data and volumes"
        echo "  reset          - Reset everything and restart"
        echo "  test           - Run API tests"
        echo "  test-rag       - Run RAG pipeline tests"
        echo "  shell-backend  - Open backend shell"
        echo "  shell-frontend - Open frontend shell"
        echo "  shell-db       - Open database shell"
        echo "  migrate        - Run database migrations"
        echo "  backup         - Create backup of database and vector store"
        echo "  help           - Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./dev.sh start"
        echo "  ./dev.sh logs backend"
        echo "  ./dev.sh test"
        ;;
esac
