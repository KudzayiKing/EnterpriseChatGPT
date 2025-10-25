# Enterprise RAG 2.0 Chat Application

A production-ready AI chat application with advanced RAG 2.0 capabilities for enterprise internal document processing.

## Features

- **Advanced RAG 2.0 Pipeline**: Multi-stage retrieval, reranking, and verification
- **Enterprise Ready**: Multi-tenancy, SSO, RBAC, audit logging
- **Real-time Chat**: ChatGPT-like interface with source citations
- **Document Processing**: PDF, DOCX, PPTX, Excel, HTML, TXT support
- **White-label**: Customizable branding per tenant
- **Analytics**: Usage tracking, performance metrics, cost analysis

## Tech Stack

**Frontend**: Next.js 14, TypeScript, Tailwind CSS  
**Backend**: Python FastAPI, LangChain, PostgreSQL, Redis  
**AI/ML**: OpenAI, Sentence Transformers, Cross-Encoders  
**Vector DB**: ChromaDB (MVP) → Pinecone/Qdrant (Production)

## Quick Start

### Prerequisites

- Node.js 18+
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Docker (optional)

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your configuration
uvicorn app.main:app --reload
```

### Frontend Setup

```bash
cd frontend
npm install
cp .env.local.example .env.local
# Edit .env.local with your configuration
npm run dev
```

### Docker Setup

```bash
docker-compose up -d
```

## Project Structure

```
enterprise-rag/
├── frontend/           # Next.js application
├── backend/            # FastAPI application
├── infrastructure/     # Docker, K8s, Terraform
└── docs/              # Documentation
```

## Documentation

- [Architecture Overview](docs/architecture.md)
- [RAG 2.0 Pipeline](docs/rag-pipeline.md)
- [API Documentation](docs/api.md)
- [Deployment Guide](docs/deployment.md)

## License

Proprietary - Enterprise License
