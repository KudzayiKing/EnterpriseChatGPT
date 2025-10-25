# Enterprise RAG 2.0 - Makefile

.PHONY: help setup start stop restart logs clean test build deploy

help:
	@echo "Enterprise RAG 2.0 - Available Commands"
	@echo "======================================="
	@echo "make setup      - Initial setup and configuration"
	@echo "make start      - Start all services"
	@echo "make stop       - Stop all services"
	@echo "make restart    - Restart all services"
	@echo "make logs       - View logs"
	@echo "make clean      - Clean up containers and volumes"
	@echo "make test       - Run API tests"
	@echo "make build      - Build Docker images"
	@echo "make deploy     - Deploy to production"
	@echo "make db-migrate - Run database migrations"
	@echo "make db-reset   - Reset database"

setup:
	@echo "🚀 Setting up Enterprise RAG 2.0..."
	@chmod +x setup.sh
	@./setup.sh

start:
	@echo "▶️  Starting services..."
	@docker-compose up -d
	@echo "✅ Services started"
	@echo "Frontend: http://localhost:3000"
	@echo "Backend: http://localhost:8000"
	@echo "API Docs: http://localhost:8000/docs"

stop:
	@echo "⏹️  Stopping services..."
	@docker-compose down
	@echo "✅ Services stopped"

restart:
	@echo "🔄 Restarting services..."
	@docker-compose restart
	@echo "✅ Services restarted"

logs:
	@docker-compose logs -f

logs-backend:
	@docker-compose logs -f backend

logs-frontend:
	@docker-compose logs -f frontend

clean:
	@echo "🧹 Cleaning up..."
	@docker-compose down -v
	@rm -rf backend/uploads/* backend/chroma_db/* backend/logs/*
	@echo "✅ Cleanup complete"

test:
	@echo "🧪 Running API tests..."
	@chmod +x test-api.sh
	@./test-api.sh

build:
	@echo "🔨 Building Docker images..."
	@docker-compose build
	@echo "✅ Build complete"

deploy:
	@echo "🚀 Deploying to production..."
	@kubectl apply -f infrastructure/k8s/
	@echo "✅ Deployment complete"

db-migrate:
	@echo "📊 Running database migrations..."
	@docker-compose exec backend alembic upgrade head
	@echo "✅ Migrations complete"

db-reset:
	@echo "⚠️  Resetting database..."
	@docker-compose down -v
	@docker-compose up -d postgres
	@sleep 5
	@docker-compose up -d backend
	@sleep 5
	@docker-compose exec backend alembic upgrade head
	@echo "✅ Database reset complete"

status:
	@echo "📊 Service Status"
	@echo "================="
	@docker-compose ps

shell-backend:
	@docker-compose exec backend /bin/bash

shell-frontend:
	@docker-compose exec frontend /bin/sh

shell-db:
	@docker-compose exec postgres psql -U postgres -d enterprise_rag

install-dev:
	@echo "📦 Installing development dependencies..."
	@cd backend && pip install -r requirements.txt
	@cd frontend && npm install
	@echo "✅ Development dependencies installed"

format:
	@echo "🎨 Formatting code..."
	@cd backend && black app/
	@cd frontend && npm run format
	@echo "✅ Code formatted"

lint:
	@echo "🔍 Linting code..."
	@cd backend && flake8 app/
	@cd frontend && npm run lint
	@echo "✅ Linting complete"
