# Setup Verification Checklist

Use this checklist to verify your Enterprise RAG 2.0 installation is complete and working correctly.

## ✅ Pre-Installation Checklist

### Required Software
- [ ] Docker installed (version 20.10+)
- [ ] Docker Compose installed (version 2.0+)
- [ ] OpenAI API key obtained
- [ ] 8GB+ RAM available
- [ ] 10GB+ disk space available

### Optional (for development)
- [ ] Node.js 18+ installed
- [ ] Python 3.11+ installed
- [ ] PostgreSQL 15+ installed
- [ ] Redis 7+ installed

## ✅ Installation Verification

### 1. Files Created
```bash
# Check all essential files exist
ls -la README.md
ls -la docker-compose.yml
ls -la setup.sh
ls -la backend/requirements.txt
ls -la frontend/package.json
```

Expected output: All files should exist

### 2. Environment Configuration
```bash
# Check environment files
ls -la .env
ls -la backend/.env
ls -la frontend/.env.local
```

Expected output: All .env files should exist

### 3. Docker Services
```bash
# Check services are running
docker-compose ps
```

Expected output:
```
NAME                STATUS              PORTS
postgres            Up                  0.0.0.0:5432->5432/tcp
redis               Up                  0.0.0.0:6379->6379/tcp
backend             Up                  0.0.0.0:8000->8000/tcp
frontend            Up                  0.0.0.0:3000->3000/tcp
```

### 4. Service Health
```bash
# Check PostgreSQL
docker-compose exec postgres pg_isready

# Check Redis
docker-compose exec redis redis-cli ping

# Check Backend API
curl http://localhost:8000/health

# Check Frontend
curl http://localhost:3000
```

Expected outputs:
- PostgreSQL: "accepting connections"
- Redis: "PONG"
- Backend: `{"status":"healthy"}`
- Frontend: HTML content

## ✅ Functional Testing

### 1. Backend API Tests

#### Health Check
```bash
curl http://localhost:8000/
```
Expected: `{"message":"Enterprise RAG 2.0 API","version":"1.0.0","status":"operational"}`

#### API Documentation
```bash
# Open in browser
open http://localhost:8000/docs
```
Expected: Interactive API documentation (Swagger UI)

#### User Registration
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "testpass123",
    "full_name": "Test User"
  }'
```
Expected: User object with id, email, username

#### User Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=testpass123"
```
Expected: `{"access_token":"...","token_type":"bearer"}`

### 2. Frontend Tests

#### Home Page
```bash
open http://localhost:3000
```
Expected: Redirect to login page

#### Login Page
```bash
open http://localhost:3000/login
```
Expected: Login/signup form

#### After Login
1. Register/login with credentials
2. Should redirect to chat interface
3. Sidebar should show "New Chat" button
4. Chat input should be visible

### 3. Document Upload Test

1. Navigate to Documents page
2. Drag & drop a test PDF file
3. Wait for processing
4. Check status changes to "completed"
5. Verify chunk count > 0

### 4. Chat Test

1. Navigate to Chat page
2. Type a question: "Hello, how are you?"
3. Press Send
4. Wait for response
5. Verify assistant message appears
6. Check conversation is saved in sidebar

### 5. Analytics Test

1. Navigate to Analytics page
2. Verify metrics are displayed:
   - Total Queries
   - Documents
   - Avg Response Time
   - Total Cost

## ✅ Database Verification

### Check Tables Created
```bash
docker-compose exec postgres psql -U postgres -d enterprise_rag -c "\dt"
```

Expected tables:
- users
- tenants
- conversations
- messages
- documents
- analytics

### Check Sample Data
```bash
# Check users
docker-compose exec postgres psql -U postgres -d enterprise_rag -c "SELECT id, username, email FROM users;"

# Check conversations
docker-compose exec postgres psql -U postgres -d enterprise_rag -c "SELECT id, title FROM conversations;"
```

## ✅ Vector Database Verification

### Check ChromaDB Directory
```bash
ls -la backend/chroma_db/
```

Expected: Directory exists with data files

### Check Collections
```bash
docker-compose exec backend python -c "
import chromadb
client = chromadb.PersistentClient(path='./chroma_db')
print('Collections:', client.list_collections())
"
```

Expected: List of tenant collections

## ✅ Log Verification

### Backend Logs
```bash
docker-compose logs backend | tail -50
```

Check for:
- [ ] No ERROR messages
- [ ] "Starting Enterprise RAG 2.0 Application"
- [ ] "Application startup complete"

### Frontend Logs
```bash
docker-compose logs frontend | tail -50
```

Check for:
- [ ] No build errors
- [ ] "Ready on http://0.0.0.0:3000"
- [ ] No module not found errors

### Database Logs
```bash
docker-compose logs postgres | tail -20
```

Check for:
- [ ] "database system is ready to accept connections"
- [ ] No connection errors

## ✅ Performance Tests

### Response Time Test
```bash
time curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=testpass123"
```

Expected: < 1 second

### Document Processing Test
1. Upload a 10-page PDF
2. Time the processing
3. Expected: < 30 seconds

### Chat Response Test
1. Send a query
2. Time the response
3. Expected: < 5 seconds

## ✅ Security Verification

### CORS Check
```bash
curl -H "Origin: http://malicious-site.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS http://localhost:8000/api/v1/auth/login
```

Expected: CORS headers only for allowed origins

### Authentication Check
```bash
# Try accessing protected endpoint without token
curl http://localhost:8000/api/v1/chat/conversations
```

Expected: 401 Unauthorized

### SQL Injection Test
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin' OR '1'='1&password=anything"
```

Expected: 401 Unauthorized (not SQL error)

## ✅ Cleanup & Restart Test

### Stop Services
```bash
docker-compose down
```

Expected: All services stop cleanly

### Remove Volumes (Optional - will delete data)
```bash
docker-compose down -v
```

### Restart Services
```bash
docker-compose up -d
```

Expected: All services start successfully

### Verify After Restart
```bash
# Wait 30 seconds
sleep 30

# Check health
curl http://localhost:8000/health
curl http://localhost:3000
```

Expected: Both services respond

## 🐛 Troubleshooting

### Issue: Services won't start
```bash
# Check Docker is running
docker ps

# Check logs
docker-compose logs

# Restart Docker
# On Mac: Restart Docker Desktop
# On Linux: sudo systemctl restart docker
```

### Issue: Port already in use
```bash
# Find process using port
lsof -i :8000  # Backend
lsof -i :3000  # Frontend
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis

# Kill process or change port in docker-compose.yml
```

### Issue: Database connection error
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check connection
docker-compose exec postgres psql -U postgres -d enterprise_rag

# Reset database
docker-compose down -v
docker-compose up -d
```

### Issue: OpenAI API error
```bash
# Verify API key
cat .env | grep OPENAI_API_KEY

# Test API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"

# Update .env and restart
docker-compose restart backend
```

### Issue: Frontend build error
```bash
# Check Node version
docker-compose exec frontend node --version

# Rebuild
docker-compose build frontend
docker-compose up -d frontend
```

## ✅ Production Readiness Checklist

Before deploying to production:

### Security
- [ ] Change SECRET_KEY in .env
- [ ] Use strong database passwords
- [ ] Enable HTTPS/TLS
- [ ] Configure firewall rules
- [ ] Enable rate limiting
- [ ] Setup audit logging
- [ ] Review CORS settings

### Performance
- [ ] Enable Redis caching
- [ ] Configure connection pooling
- [ ] Setup CDN for frontend
- [ ] Optimize database indexes
- [ ] Enable compression

### Monitoring
- [ ] Setup logging aggregation
- [ ] Configure alerts
- [ ] Enable metrics collection
- [ ] Setup uptime monitoring
- [ ] Configure backup strategy

### Scalability
- [ ] Test with load testing tools
- [ ] Configure auto-scaling
- [ ] Setup load balancer
- [ ] Optimize database queries
- [ ] Enable horizontal scaling

## 📊 Success Criteria

Your installation is successful if:

- ✅ All services are running
- ✅ Can register and login users
- ✅ Can upload and process documents
- ✅ Can send messages and get responses
- ✅ Analytics dashboard shows data
- ✅ No errors in logs
- ✅ Response times are acceptable
- ✅ Security checks pass

## 🎉 Next Steps

Once verification is complete:

1. Read the [Architecture Documentation](docs/architecture.md)
2. Explore the [RAG Pipeline](docs/rag-pipeline.md)
3. Review the [API Documentation](docs/api.md)
4. Plan your [Production Deployment](docs/deployment.md)
5. Customize for your use case

## 📞 Support

If you encounter issues:

1. Check the logs: `docker-compose logs`
2. Review [Troubleshooting](#-troubleshooting)
3. Search GitHub issues
4. Contact support: support@yourdomain.com

---

**Verification Date**: _____________
**Verified By**: _____________
**Status**: ⬜ Pass ⬜ Fail
**Notes**: _____________
