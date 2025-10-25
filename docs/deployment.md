# Deployment Guide

## Prerequisites

- Docker & Docker Compose
- Node.js 18+
- Python 3.11+
- PostgreSQL 15+
- Redis 7+

## Local Development Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd enterprise-rag
```

### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Setup environment
cp .env.example .env
# Edit .env with your configuration

# Run migrations
alembic upgrade head

# Start server
uvicorn app.main:app --reload
```

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Setup environment
cp .env.local.example .env.local
# Edit .env.local with your configuration

# Start development server
npm run dev
```

### 4. Docker Compose Setup (Recommended)

```bash
# Copy environment file
cp .env.example .env
# Edit .env with your OpenAI API key

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Production Deployment

### Option 1: Docker Deployment

```bash
# Build images
docker-compose -f docker-compose.prod.yml build

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Run migrations
docker-compose exec backend alembic upgrade head
```

### Option 2: Kubernetes Deployment

```bash
# Apply configurations
kubectl apply -f infrastructure/k8s/

# Check status
kubectl get pods
kubectl get services

# View logs
kubectl logs -f deployment/backend
```

### Option 3: Cloud Platform Deployment

#### AWS Deployment

1. **Setup RDS (PostgreSQL)**
2. **Setup ElastiCache (Redis)**
3. **Setup S3 for file storage**
4. **Deploy to ECS/EKS**

#### Google Cloud Deployment

1. **Setup Cloud SQL (PostgreSQL)**
2. **Setup Memorystore (Redis)**
3. **Setup Cloud Storage**
4. **Deploy to Cloud Run/GKE**

## Environment Variables

### Backend (.env)

```bash
# Database
DATABASE_URL=postgresql://user:password@host:5432/dbname
REDIS_URL=redis://host:6379

# OpenAI
OPENAI_API_KEY=your_api_key

# JWT
SECRET_KEY=your_secret_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Application
ENVIRONMENT=production
DEBUG=False
CORS_ORIGINS=https://yourdomain.com

# File Upload
MAX_UPLOAD_SIZE=52428800
UPLOAD_DIR=/app/uploads

# Vector DB
CHROMA_PERSIST_DIR=/app/chroma_db
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
```

### Frontend (.env.local)

```bash
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
```

## Database Migrations

```bash
# Create migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## Monitoring Setup

### Application Monitoring

```bash
# Install monitoring tools
pip install prometheus-client
npm install @opentelemetry/api
```

### Log Aggregation

- Setup ELK Stack (Elasticsearch, Logstash, Kibana)
- Or use cloud services (CloudWatch, Stackdriver)

## Backup & Recovery

### Database Backup

```bash
# PostgreSQL backup
pg_dump -h localhost -U postgres enterprise_rag > backup.sql

# Restore
psql -h localhost -U postgres enterprise_rag < backup.sql
```

### Vector Database Backup

```bash
# Backup ChromaDB
tar -czf chroma_backup.tar.gz chroma_db/

# Restore
tar -xzf chroma_backup.tar.gz
```

## Security Checklist

- [ ] Change default SECRET_KEY
- [ ] Enable HTTPS/TLS
- [ ] Setup firewall rules
- [ ] Enable database encryption
- [ ] Setup backup strategy
- [ ] Configure rate limiting
- [ ] Enable audit logging
- [ ] Setup monitoring alerts
- [ ] Review CORS settings
- [ ] Enable API authentication

## Performance Optimization

### Backend

- Enable Redis caching
- Use connection pooling
- Optimize database queries
- Enable compression

### Frontend

- Enable Next.js production build
- Setup CDN for static assets
- Enable image optimization
- Implement code splitting

## Troubleshooting

### Common Issues

**Database Connection Error**
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check connection
psql -h localhost -U postgres -d enterprise_rag
```

**Redis Connection Error**
```bash
# Check Redis is running
docker-compose ps redis

# Test connection
redis-cli ping
```

**OpenAI API Error**
- Verify API key is correct
- Check API quota and billing
- Review rate limits

## Scaling Guide

### Horizontal Scaling

```bash
# Scale backend
docker-compose up -d --scale backend=3

# Kubernetes scaling
kubectl scale deployment backend --replicas=3
```

### Load Balancing

- Setup Nginx/HAProxy
- Configure health checks
- Enable session affinity

## Maintenance

### Regular Tasks

- Monitor disk space
- Review logs
- Update dependencies
- Backup databases
- Review security patches
- Monitor API costs
