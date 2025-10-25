# Project Structure

## Complete Directory Tree

```
enterprise-rag/
├── README.md                          # Main project documentation
├── QUICKSTART.md                      # Quick start guide
├── PROJECT_OVERVIEW.md                # Comprehensive project overview
├── CONTRIBUTING.md                    # Contribution guidelines
├── CHANGELOG.md                       # Version history
├── LICENSE                            # Enterprise license
├── STRUCTURE.md                       # This file
├── .gitignore                         # Git ignore rules
├── .env.example                       # Environment variables template
├── docker-compose.yml                 # Docker orchestration
├── setup.sh                           # Automated setup script
│
├── backend/                           # Python FastAPI Backend
│   ├── Dockerfile                     # Backend container config
│   ├── requirements.txt               # Python dependencies
│   ├── alembic.ini                    # Database migration config
│   ├── .env.example                   # Backend environment template
│   │
│   ├── alembic/                       # Database migrations
│   │   ├── env.py                     # Alembic environment
│   │   ├── script.py.mako             # Migration template
│   │   └── versions/                  # Migration files
│   │
│   ├── app/                           # Main application
│   │   ├── __init__.py
│   │   ├── main.py                    # FastAPI app entry point
│   │   │
│   │   ├── core/                      # Core functionality
│   │   │   ├── __init__.py
│   │   │   ├── config.py              # Configuration management
│   │   │   ├── rag_orchestrator.py   # RAG 2.0 pipeline
│   │   │   └── document_processor.py # Document processing
│   │   │
│   │   ├── db/                        # Database layer
│   │   │   ├── __init__.py
│   │   │   ├── database.py            # Database connection
│   │   │   └── models.py              # SQLAlchemy models
│   │   │
│   │   └── api/                       # API endpoints
│   │       ├── __init__.py
│   │       └── v1/                    # API version 1
│   │           ├── __init__.py
│   │           ├── auth.py            # Authentication endpoints
│   │           ├── chat.py            # Chat endpoints
│   │           ├── documents.py       # Document endpoints
│   │           └── analytics.py       # Analytics endpoints
│   │
│   ├── uploads/                       # Uploaded files (created at runtime)
│   ├── chroma_db/                     # Vector database (created at runtime)
│   └── logs/                          # Application logs (created at runtime)
│
├── frontend/                          # Next.js Frontend
│   ├── Dockerfile                     # Frontend container config
│   ├── package.json                   # Node dependencies
│   ├── tsconfig.json                  # TypeScript config
│   ├── next.config.js                 # Next.js config
│   ├── tailwind.config.ts             # Tailwind CSS config
│   ├── postcss.config.js              # PostCSS config
│   ├── .env.local.example             # Frontend environment template
│   │
│   ├── app/                           # Next.js App Router
│   │   ├── layout.tsx                 # Root layout
│   │   ├── page.tsx                   # Home page
│   │   ├── globals.css                # Global styles
│   │   │
│   │   ├── login/                     # Login page
│   │   │   └── page.tsx
│   │   │
│   │   ├── chat/                      # Chat interface
│   │   │   └── page.tsx
│   │   │
│   │   ├── documents/                 # Document management
│   │   │   └── page.tsx
│   │   │
│   │   └── analytics/                 # Analytics dashboard
│   │       └── page.tsx
│   │
│   ├── lib/                           # Utilities
│   │   ├── api.ts                     # API client
│   │   └── store.ts                   # State management
│   │
│   ├── components/                    # React components (to be added)
│   ├── hooks/                         # Custom hooks (to be added)
│   └── types/                         # TypeScript types (to be added)
│
├── infrastructure/                    # Infrastructure as Code
│   └── k8s/                          # Kubernetes configs
│       └── deployment.yaml            # K8s deployment
│
└── docs/                             # Documentation
    ├── architecture.md               # Architecture overview
    ├── rag-pipeline.md              # RAG pipeline details
    ├── api.md                       # API documentation
    └── deployment.md                # Deployment guide
```

## Key Components

### Backend Components

#### 1. Core (`backend/app/core/`)
- **config.py**: Application configuration and settings
- **rag_orchestrator.py**: Main RAG 2.0 pipeline orchestration
- **document_processor.py**: Document parsing and chunking

#### 2. Database (`backend/app/db/`)
- **database.py**: SQLAlchemy engine and session management
- **models.py**: Database models (User, Tenant, Conversation, Message, Document, Analytics)

#### 3. API (`backend/app/api/v1/`)
- **auth.py**: User registration, login, JWT authentication
- **chat.py**: Message sending, conversation management
- **documents.py**: File upload, processing, management
- **analytics.py**: Usage statistics and metrics

### Frontend Components

#### 1. Pages (`frontend/app/`)
- **page.tsx**: Landing/redirect page
- **login/page.tsx**: Authentication page
- **chat/page.tsx**: Main chat interface
- **documents/page.tsx**: Document upload and management
- **analytics/page.tsx**: Analytics dashboard

#### 2. Libraries (`frontend/lib/`)
- **api.ts**: Axios-based API client with authentication
- **store.ts**: Zustand state management

### Infrastructure

#### 1. Docker
- **docker-compose.yml**: Local development orchestration
- **Dockerfile** (backend): Python FastAPI container
- **Dockerfile** (frontend): Next.js container

#### 2. Kubernetes
- **deployment.yaml**: Production deployment configuration

## Data Flow

### 1. Document Upload Flow
```
User → Frontend (Upload) → Backend API → Document Processor
                                              ↓
                                         File Storage
                                              ↓
                                         Text Extraction
                                              ↓
                                         Smart Chunking
                                              ↓
                                         Embedding Generation
                                              ↓
                                         Vector Database (ChromaDB)
```

### 2. Chat Query Flow
```
User → Frontend (Query) → Backend API → RAG Orchestrator
                                              ↓
                                         Query Expansion
                                              ↓
                                         Vector Search
                                              ↓
                                         Cross-Encoder Rerank
                                              ↓
                                         Context Compression
                                              ↓
                                         LLM Generation
                                              ↓
                                         Verification
                                              ↓
                                    Response with Sources
                                              ↓
                                         Frontend (Display)
```

### 3. Authentication Flow
```
User → Frontend (Login) → Backend API → JWT Generation
                                              ↓
                                         Token Storage
                                              ↓
                                    Authenticated Requests
```

## Database Schema

### Tables

1. **users**
   - id, email, username, hashed_password
   - full_name, is_active, is_superuser
   - tenant_id, created_at, updated_at

2. **tenants**
   - id, name, domain, settings
   - is_active, created_at

3. **conversations**
   - id, user_id, title
   - created_at, updated_at

4. **messages**
   - id, conversation_id, role, content
   - sources, metadata, created_at

5. **documents**
   - id, user_id, tenant_id
   - filename, file_path, file_type, file_size
   - status, chunk_count, metadata, created_at

6. **analytics**
   - id, user_id, query
   - response_time, tokens_used, cost
   - satisfaction_score, metadata, created_at

## Environment Variables

### Backend (.env)
```
DATABASE_URL          # PostgreSQL connection
REDIS_URL            # Redis connection
OPENAI_API_KEY       # OpenAI API key
SECRET_KEY           # JWT secret
CHUNK_SIZE           # Document chunk size
TOP_K_RETRIEVAL      # Number of chunks to retrieve
```

### Frontend (.env.local)
```
NEXT_PUBLIC_API_URL  # Backend API URL
```

## Port Mapping

- **3000**: Frontend (Next.js)
- **8000**: Backend API (FastAPI)
- **5432**: PostgreSQL
- **6379**: Redis

## File Storage

### Development
- Local filesystem: `backend/uploads/`
- Vector DB: `backend/chroma_db/`

### Production
- Cloud storage: AWS S3 / Google Cloud Storage
- Vector DB: Pinecone / Qdrant

## Dependencies

### Backend (Python)
- fastapi: Web framework
- sqlalchemy: ORM
- langchain: RAG orchestration
- chromadb: Vector database
- openai: LLM integration
- sentence-transformers: Embeddings

### Frontend (Node.js)
- next: React framework
- react: UI library
- tailwindcss: Styling
- axios: HTTP client
- zustand: State management

## Build & Deploy

### Development
```bash
docker-compose up -d
```

### Production
```bash
kubectl apply -f infrastructure/k8s/
```

## Monitoring

### Logs
- Backend: `docker-compose logs backend`
- Frontend: `docker-compose logs frontend`
- Database: `docker-compose logs postgres`

### Metrics
- API response time
- Token usage
- Query success rate
- User activity

## Security

### Authentication
- JWT tokens
- Password hashing (bcrypt)
- Token expiration

### Authorization
- Role-based access control
- Tenant isolation
- Resource ownership validation

### Data Protection
- SQL injection prevention
- Input validation
- CORS configuration
- Rate limiting (planned)
