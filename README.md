# EnterpriseChatGPT - Enterprise RAG 2.0 with Local AI Models

A production-ready AI chat application with advanced RAG 2.0 capabilities, powered entirely by **local open-source models**. Zero external API calls, complete data sovereignty, and no ongoing AI costs.

## 🚀 Key Features

- **100% Local AI Models**: Powered by Llama 3.1 8B via Ollama - no data leaves your infrastructure
- **Zero External API Costs**: No OpenAI, Anthropic, or third-party API dependencies
- **Advanced RAG 2.0 Pipeline**: Multi-stage retrieval with local embeddings and reranking
- **Enterprise Ready**: Multi-tenancy, SSO, RBAC, audit logging
- **Real-time Chat**: ChatGPT-like interface with streaming responses and source citations
- **Document Processing**: PDF, DOCX, PPTX, Excel, HTML, TXT support with local processing
- **Dual Performance Modes**: Fast (5-15s) and Accurate (60-90s) modes
- **Privacy Compliant**: GDPR, HIPAA, SOC2 ready - complete data sovereignty
- **White-label Ready**: Customizable branding per tenant
- **Analytics Dashboard**: Usage tracking, performance metrics, conversation analytics
- **Long-press Delete**: Intuitive chat history management

## 🛠️ Tech Stack

**Frontend**: Next.js 14, TypeScript, React, Tailwind CSS  
**Backend**: Python FastAPI, LangChain, PostgreSQL, Redis  
**AI/ML**: 
- **LLM**: Llama 3.1 8B (via Ollama)
- **Embeddings**: sentence-transformers/all-MiniLM-L6-v2 (local)
- **Vector Store**: ChromaDB (local)
**Infrastructure**: Docker, Kubernetes ready, Nginx

## 🚀 Quick Start

### Prerequisites

- **Node.js 18+**
- **Python 3.11+**
- **PostgreSQL 15+**
- **Redis 7+** (optional, for caching)
- **Ollama** (for local LLM)
- **Docker** (optional, for containerized deployment)

### Option 1: Automated Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/EnterpriseChatGPT.git
cd EnterpriseChatGPT

# Run the automated setup script
./start-local.sh
```

This will:
- Install Ollama and download Llama 3.1 8B model
- Set up PostgreSQL and Redis
- Install backend and frontend dependencies
- Start both services

Access the app at:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

### Option 2: Manual Setup

#### 1. Install Ollama and Download Model

```bash
# Install Ollama (macOS/Linux)
curl -fsSL https://ollama.com/install.sh | sh

# Download Llama 3.1 8B model
ollama pull llama3.1:8b

# Verify Ollama is running
ollama list
```

#### 2. Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env - set USE_LOCAL_MODELS=true

# Run migrations
alembic upgrade head

# Start backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### 3. Frontend Setup

```bash
cd frontend
npm install

# Configure environment
cp .env.local.example .env.local
# Edit .env.local with your API URL

# Start frontend
npm run dev
```

### Option 3: Docker Setup

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📁 Project Structure

```
EnterpriseChatGPT/
├── frontend/              # Next.js 14 application
│   ├── app/              # App router pages
│   │   ├── chat/         # Main chat interface
│   │   ├── documents/    # Document management
│   │   ├── analytics/    # Analytics dashboard
│   │   └── login/        # Authentication
│   └── lib/              # API client and state management
├── backend/              # FastAPI application
│   ├── app/
│   │   ├── api/          # API endpoints
│   │   ├── core/         # RAG orchestrator, config
│   │   ├── db/           # Database models
│   │   └── main.py       # Application entry point
│   └── alembic/          # Database migrations
├── infrastructure/       # Docker, K8s configs
├── docs/                 # Documentation
├── proposals/            # Industry-specific proposals
└── scripts/              # Utility scripts
```

## 📚 Documentation

- [Architecture Overview](docs/architecture.md)
- [RAG 2.0 Pipeline](docs/rag-pipeline.md)
- [API Documentation](docs/api.md)
- [Deployment Guide](docs/deployment.md)
- [Enterprise Deployment Guide](ENTERPRISE_DEPLOYMENT_GUIDE.md)
- [Local Models Setup](SETUP_LOCAL_MODELS.md)
- [Cloud vs Local Comparison](CLOUD_VS_LOCAL.md)

## 🎯 Use Cases

### Target Industries
- **Healthcare**: HIPAA-compliant document processing
- **Financial Services**: SEC/FINRA compliant AI chat
- **Legal**: Attorney-client privilege protection
- **Government**: FedRAMP/FISMA ready deployments
- **Manufacturing**: IP protection and technical documentation

### Common Applications
- Internal knowledge base search
- Document Q&A and analysis
- Contract review and analysis
- Compliance document processing
- Technical documentation assistance
- Customer support knowledge base

## 💰 Cost Savings

**vs. ChatGPT Enterprise** (200 users, 3 years):
- ChatGPT Enterprise: **$432,000**
- EnterpriseChatGPT: **$42,000** (one-time + support)
- **Savings: $390,000 (90%)**

**Benefits:**
- ✅ No per-query costs
- ✅ No user limits
- ✅ No data breach liability
- ✅ Complete data sovereignty
- ✅ Predictable costs

## 🔒 Security & Privacy

- **100% On-Premise**: All AI processing happens locally
- **Zero External Calls**: No data sent to OpenAI, Anthropic, or any third party
- **Air-Gapped Ready**: Can run completely offline
- **Compliance Ready**: GDPR, HIPAA, SOC2, FedRAMP architecture
- **Audit Trails**: Complete logging of all queries and access
- **Encryption**: AES-256 at rest, TLS 1.3 in transit

## 🛠️ Management Scripts

```bash
# List all registered users
python list_users.py

# Reset user password
python reset_password.py

# Create new user
python create_user.py

# Test login
python test_login.py

# Start services
./start-local.sh

# Stop services
./stop-local.sh

# Monitor services
./monitor.sh

# Run tests
./test-api.sh
```

## 🚀 Deployment Options

1. **Docker Compose** (Recommended for small-mid size)
2. **Kubernetes** (Recommended for enterprise scale)
3. **Bare Metal / VM** (For air-gapped environments)

See [Enterprise Deployment Guide](ENTERPRISE_DEPLOYMENT_GUIDE.md) for detailed instructions.

## 🤝 Contributing

This is a proprietary enterprise application. For feature requests or bug reports, please contact the development team.

## 📄 License

Proprietary - Enterprise License

## 📞 Support

For enterprise support, deployment assistance, or custom features:
- Email: sales@enterprisechatgpt.com
- Documentation: See `/docs` folder
- Issues: Contact your account manager

## 🎉 What's New in v2.0

- ✅ 100% Local AI models (Llama 3.1 8B)
- ✅ Zero external API dependencies
- ✅ Improved chat flow with instant message display
- ✅ Long-press delete for chat history
- ✅ Enhanced streaming responses
- ✅ Better mobile support
- ✅ Updated About section with accurate tech stack
- ✅ Comprehensive deployment guides
- ✅ Industry-specific proposals

---

**Built with ❤️ for enterprises that value privacy, security, and cost efficiency.**
