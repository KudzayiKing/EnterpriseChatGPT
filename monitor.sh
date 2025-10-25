#!/bin/bash

# Enterprise RAG 2.0 - Monitoring Script
# Real-time monitoring of services, resources, and logs

echo "📊 Enterprise RAG 2.0 - System Monitor"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if services are running
check_services() {
    echo -e "${BLUE}=== Service Status ===${NC}"
    docker-compose ps
    echo ""
}

# Check resource usage
check_resources() {
    echo -e "${BLUE}=== Resource Usage ===${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
}

# Check API health
check_api_health() {
    echo -e "${BLUE}=== API Health ===${NC}"
    
    # Backend health
    echo -n "Backend API: "
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Healthy${NC}"
    else
        echo -e "${RED}✗ Unhealthy${NC}"
    fi
    
    # Frontend health
    echo -n "Frontend: "
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Healthy${NC}"
    else
        echo -e "${RED}✗ Unhealthy${NC}"
    fi
    
    # Database health
    echo -n "PostgreSQL: "
    if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Healthy${NC}"
    else
        echo -e "${RED}✗ Unhealthy${NC}"
    fi
    
    # Redis health
    echo -n "Redis: "
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Healthy${NC}"
    else
        echo -e "${RED}✗ Unhealthy${NC}"
    fi
    echo ""
}

# Check disk usage
check_disk() {
    echo -e "${BLUE}=== Disk Usage ===${NC}"
    echo "Uploads:"
    du -sh backend/uploads/ 2>/dev/null || echo "0B"
    echo "Vector DB:"
    du -sh backend/chroma_db/ 2>/dev/null || echo "0B"
    echo "Logs:"
    du -sh backend/logs/ 2>/dev/null || echo "0B"
    echo ""
}

# Check database stats
check_database() {
    echo -e "${BLUE}=== Database Statistics ===${NC}"
    docker-compose exec -T postgres psql -U postgres -d enterprise_rag -c "
        SELECT 
            'Users' as table_name, COUNT(*) as count FROM users
        UNION ALL
        SELECT 'Conversations', COUNT(*) FROM conversations
        UNION ALL
        SELECT 'Messages', COUNT(*) FROM messages
        UNION ALL
        SELECT 'Documents', COUNT(*) FROM documents
        UNION ALL
        SELECT 'Analytics', COUNT(*) FROM analytics;
    " 2>/dev/null || echo "Database not accessible"
    echo ""
}

# Check recent logs
check_logs() {
    echo -e "${BLUE}=== Recent Logs (Last 10 lines) ===${NC}"
    echo ""
    echo -e "${YELLOW}Backend:${NC}"
    docker-compose logs --tail=10 backend 2>/dev/null | tail -10
    echo ""
    echo -e "${YELLOW}Frontend:${NC}"
    docker-compose logs --tail=10 frontend 2>/dev/null | tail -10
    echo ""
}

# Check API response times
check_performance() {
    echo -e "${BLUE}=== API Performance ===${NC}"
    
    echo -n "Health endpoint: "
    time_ms=$(curl -o /dev/null -s -w '%{time_total}\n' http://localhost:8000/health)
    echo "${time_ms}s"
    
    echo -n "Root endpoint: "
    time_ms=$(curl -o /dev/null -s -w '%{time_total}\n' http://localhost:8000/)
    echo "${time_ms}s"
    echo ""
}

# Main monitoring loop
monitor_mode=$1

case $monitor_mode in
    watch)
        # Continuous monitoring
        while true; do
            clear
            echo "📊 Enterprise RAG 2.0 - Live Monitor"
            echo "======================================"
            echo "Press Ctrl+C to exit"
            echo ""
            check_services
            check_resources
            check_api_health
            check_disk
            sleep 5
        done
        ;;
    
    logs)
        # Follow logs
        service=${2:-""}
        if [ -z "$service" ]; then
            docker-compose logs -f
        else
            docker-compose logs -f $service
        fi
        ;;
    
    stats)
        # Show statistics
        check_services
        check_resources
        check_api_health
        check_disk
        check_database
        check_performance
        ;;
    
    errors)
        # Show recent errors
        echo -e "${RED}=== Recent Errors ===${NC}"
        echo ""
        echo "Backend errors:"
        docker-compose logs backend 2>&1 | grep -i "error" | tail -20
        echo ""
        echo "Frontend errors:"
        docker-compose logs frontend 2>&1 | grep -i "error" | tail -20
        ;;
    
    help|*)
        echo "Usage: ./monitor.sh [command]"
        echo ""
        echo "Commands:"
        echo "  watch    - Continuous monitoring (refreshes every 5s)"
        echo "  logs     - Follow all logs"
        echo "  stats    - Show detailed statistics"
        echo "  errors   - Show recent errors"
        echo "  help     - Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./monitor.sh watch"
        echo "  ./monitor.sh logs backend"
        echo "  ./monitor.sh stats"
        ;;
esac
