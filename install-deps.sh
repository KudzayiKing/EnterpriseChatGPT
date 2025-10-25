#!/bin/bash

# Enterprise RAG 2.0 - Dependency Installation Script
# Installs all required dependencies for local development

echo "📦 Enterprise RAG 2.0 - Dependency Installer"
echo "============================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
fi

echo "Detected OS: $OS"
echo ""

# Check if running with Docker (recommended)
echo -e "${BLUE}=== Installation Mode ===${NC}"
echo ""
echo "Choose installation mode:"
echo "  1) Docker (Recommended) - No local dependencies needed"
echo "  2) Local Development - Install all dependencies locally"
echo ""
read -p "Enter choice (1 or 2): " mode

if [ "$mode" = "1" ]; then
    echo ""
    echo -e "${BLUE}=== Docker Installation ===${NC}"
    echo ""
    
    # Check Docker
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker is installed${NC}"
        docker --version
    else
        echo -e "${RED}✗ Docker is not installed${NC}"
        echo ""
        echo "Please install Docker:"
        if [ "$OS" = "macos" ]; then
            echo "  brew install --cask docker"
            echo "  Or download from: https://www.docker.com/products/docker-desktop"
        elif [ "$OS" = "linux" ]; then
            echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
            echo "  sudo sh get-docker.sh"
        else
            echo "  Download from: https://www.docker.com/products/docker-desktop"
        fi
        exit 1
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}✓ Docker Compose is installed${NC}"
        docker-compose --version
    else
        echo -e "${RED}✗ Docker Compose is not installed${NC}"
        echo ""
        echo "Please install Docker Compose:"
        if [ "$OS" = "macos" ]; then
            echo "  Included with Docker Desktop"
        elif [ "$OS" = "linux" ]; then
            echo "  sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
            echo "  sudo chmod +x /usr/local/bin/docker-compose"
        fi
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✓ All Docker dependencies are installed${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./setup.sh"
    echo "  2. Edit .env with your OpenAI API key"
    echo "  3. Run: docker-compose restart"
    echo ""
    
elif [ "$mode" = "2" ]; then
    echo ""
    echo -e "${BLUE}=== Local Development Installation ===${NC}"
    echo ""
    
    # Install Python dependencies
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗ Python 3 is not installed${NC}"
        echo "Please install Python 3.11 or higher"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Python is installed${NC}"
    python3 --version
    
    # Create virtual environment
    echo "Creating Python virtual environment..."
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    
    # Install requirements
    echo "Installing Python packages..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Python dependencies installed${NC}"
    else
        echo -e "${RED}✗ Failed to install Python dependencies${NC}"
        exit 1
    fi
    
    cd ..
    
    # Install Node.js dependencies
    echo ""
    echo -e "${YELLOW}Installing Node.js dependencies...${NC}"
    
    if ! command -v node &> /dev/null; then
        echo -e "${RED}✗ Node.js is not installed${NC}"
        echo "Please install Node.js 18 or higher"
        if [ "$OS" = "macos" ]; then
            echo "  brew install node"
        elif [ "$OS" = "linux" ]; then
            echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
            echo "  sudo apt-get install -y nodejs"
        fi
        exit 1
    fi
    
    echo -e "${GREEN}✓ Node.js is installed${NC}"
    node --version
    npm --version
    
    # Install frontend dependencies
    echo "Installing Node.js packages..."
    cd frontend
    npm install
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Node.js dependencies installed${NC}"
    else
        echo -e "${RED}✗ Failed to install Node.js dependencies${NC}"
        exit 1
    fi
    
    cd ..
    
    # Install PostgreSQL
    echo ""
    echo -e "${YELLOW}Checking PostgreSQL...${NC}"
    
    if command -v psql &> /dev/null; then
        echo -e "${GREEN}✓ PostgreSQL is installed${NC}"
        psql --version
    else
        echo -e "${YELLOW}⚠ PostgreSQL is not installed${NC}"
        echo "Please install PostgreSQL 15 or higher:"
        if [ "$OS" = "macos" ]; then
            echo "  brew install postgresql@15"
        elif [ "$OS" = "linux" ]; then
            echo "  sudo apt-get install postgresql-15"
        fi
    fi
    
    # Install Redis
    echo ""
    echo -e "${YELLOW}Checking Redis...${NC}"
    
    if command -v redis-cli &> /dev/null; then
        echo -e "${GREEN}✓ Redis is installed${NC}"
        redis-cli --version
    else
        echo -e "${YELLOW}⚠ Redis is not installed${NC}"
        echo "Please install Redis 7 or higher:"
        if [ "$OS" = "macos" ]; then
            echo "  brew install redis"
        elif [ "$OS" = "linux" ]; then
            echo "  sudo apt-get install redis-server"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}✓ Local development dependencies installed${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Start PostgreSQL and Redis"
    echo "  2. Create database: createdb enterprise_rag"
    echo "  3. Copy .env files:"
    echo "     cp backend/.env.example backend/.env"
    echo "     cp frontend/.env.local.example frontend/.env.local"
    echo "  4. Edit .env files with your configuration"
    echo "  5. Run migrations: cd backend && alembic upgrade head"
    echo "  6. Start backend: cd backend && uvicorn app.main:app --reload"
    echo "  7. Start frontend: cd frontend && npm run dev"
    echo ""
    
else
    echo "Invalid choice"
    exit 1
fi

# Make scripts executable
echo -e "${BLUE}=== Making scripts executable ===${NC}"
chmod +x setup.sh dev.sh test-api.sh test-rag.sh monitor.sh benchmark.sh
echo -e "${GREEN}✓ Scripts are now executable${NC}"
echo ""

echo "========================================"
echo -e "${GREEN}✓ Installation Complete!${NC}"
echo ""
echo "Available scripts:"
echo "  ./setup.sh       - Quick setup with Docker"
echo "  ./dev.sh         - Development helper commands"
echo "  ./test-api.sh    - Test API endpoints"
echo "  ./test-rag.sh    - Test RAG pipeline"
echo "  ./monitor.sh     - Monitor system health"
echo "  ./benchmark.sh   - Run performance benchmarks"
echo ""
