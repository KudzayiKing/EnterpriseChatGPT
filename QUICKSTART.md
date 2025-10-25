# Quick Start Guide

Get your Enterprise RAG 2.0 application running in 5 minutes!

## Prerequisites

- Docker & Docker Compose installed
- OpenAI API key ([Get one here](https://platform.openai.com/api-keys))

## Installation

### Option 1: Automated Setup (Recommended)

```bash
# Make setup script executable
chmod +x setup.sh

# Run setup
./setup.sh

# Edit .env and add your OpenAI API key
nano .env  # or use your preferred editor

# Restart services
docker-compose restart
```

### Option 2: Manual Setup

```bash
# 1. Create environment file
cp .env.example .env

# 2. Edit .env and add your OpenAI API key
# OPENAI_API_KEY=sk-...

# 3. Start services
docker-compose up -d

# 4. Wait for services to start (30 seconds)
docker-compose logs -f
```

## Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

## First Steps

### 1. Create an Account

1. Open http://localhost:3000
2. Click "Sign up"
3. Fill in your details
4. Click "Create account"

### 2. Upload Documents

1. Navigate to "Documents" from the sidebar
2. Drag & drop your files (PDF, DOCX, PPTX, etc.)
3. Wait for processing to complete

### 3. Start Chatting

1. Go back to "Chat"
2. Ask questions about your documents
3. Get AI-powered answers with source citations

## Example Queries

Try these queries after uploading documents:

- "Summarize the main points from the uploaded documents"
- "What are the key findings in the research paper?"
- "Explain the methodology used in the study"
- "Compare the results across different sections"

## Troubleshooting

### Services won't start

```bash
# Check Docker is running
docker ps

# View logs
docker-compose logs

# Restart services
docker-compose down
docker-compose up -d
```

### Can't connect to backend

```bash
# Check backend is running
docker-compose ps backend

# View backend logs
docker-compose logs backend

# Restart backend
docker-compose restart backend
```

### OpenAI API errors

1. Verify your API key is correct in `.env`
2. Check you have credits in your OpenAI account
3. Restart services after updating `.env`

## Configuration

### Adjust RAG Parameters

Edit `backend/.env`:

```bash
# Chunk size for document splitting
CHUNK_SIZE=512

# Number of chunks to retrieve
TOP_K_RETRIEVAL=10

# Number of chunks after reranking
RERANK_TOP_K=5
```

### Change LLM Model

Edit `backend/app/core/rag_orchestrator.py`:

```python
self.llm = ChatOpenAI(
    model="gpt-4-turbo-preview",  # Change to gpt-3.5-turbo for lower cost
    temperature=0.7,
)
```

## Development Mode

### Backend Development

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env
uvicorn app.main:app --reload
```

### Frontend Development

```bash
cd frontend
npm install
cp .env.local.example .env.local
# Edit .env.local
npm run dev
```

## Production Deployment

See [Deployment Guide](docs/deployment.md) for production setup.

## Next Steps

- Read the [Architecture Documentation](docs/architecture.md)
- Explore the [RAG Pipeline](docs/rag-pipeline.md)
- Check the [API Documentation](docs/api.md)
- Configure [Multi-tenancy](docs/multi-tenancy.md)

## Support

- GitHub Issues: [Report bugs](https://github.com/yourorg/enterprise-rag/issues)
- Documentation: [Full docs](docs/)
- Email: support@yourdomain.com

## License

Enterprise License - See LICENSE file for details
