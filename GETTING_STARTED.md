# Getting Started with Enterprise RAG 2.0

Welcome! This guide will help you get your Enterprise RAG 2.0 application up and running.

## 🚀 Quick Start (5 Minutes)

### Prerequisites
- Docker & Docker Compose installed
- OpenAI API key ([Get one here](https://platform.openai.com/api-keys))

### Installation

```bash
# 1. Install dependencies (if needed)
./install-deps.sh

# 2. Run automated setup
./setup.sh

# 3. Add your OpenAI API key
nano .env  # Edit OPENAI_API_KEY=your_key_here

# 4. Restart services
docker-compose restart

# 5. Open the application
open http://localhost:3000
```

That's it! Your application is now running.

## 📚 Available Scripts

We've created several helper scripts to make development easier:

### Development Helper
```bash
./dev.sh start          # Start all services
./dev.sh stop           # Stop all services
./dev.sh restart        # Restart services
./dev.sh logs           # View logs
./dev.sh status         # Check service status
./dev.sh shell-backend  # Open backend shell
./dev.sh help           # Show all commands
```

### Testing
```bash
./test-api.sh          # Test all API endpoints
./test-rag.sh          # Test RAG pipeline
```

### Monitoring
```bash
./monitor.sh watch     # Live monitoring dashboard
./monitor.sh logs      # Follow logs
./monitor.sh stats     # Show statistics
./monitor.sh errors    # Show recent errors
```

### Performance
```bash
./benchmark.sh         # Run performance benchmarks
```

## 🎯 First Steps

### 1. Create Your Account
1. Open http://localhost:3000
2. Click "Sign up"
3. Enter your details
4. Click "Create account"

### 2. Upload Documents
1. Click "Documents" in the sidebar
2. Drag & drop your files (PDF, DOCX, PPTX, etc.)
3. Wait for processing to complete (status: "completed")

### 3. Start Chatting
1. Go back to "Chat"
2. Ask questions about your documents
3. Get AI-powered answers with source citations

## 📖 Example Workflow

### Upload a Document
```bash
# Via UI: Drag & drop in Documents page

# Via API:
curl -X POST http://localhost:8000/api/v1/documents/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@document.pdf"
```

### Ask Questions
```bash
# Via UI: Type in chat interface

# Via API:
curl -X POST http://localhost:8000/api/v1/chat/message \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"What is this document about?"}'
```

## 🔧 Configuration

### Environment Variables

**Backend (.env)**
```bash
OPENAI_API_KEY=sk-...           # Your OpenAI API key
CHUNK_SIZE=512                  # Document chunk size
TOP_K_RETRIEVAL=10             # Number of chunks to retrieve
RERANK_TOP_K=5                 # Number after reranking
```

**Frontend (.env.local)**
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### Adjust RAG Parameters

Edit `backend/.env`:
- `CHUNK_SIZE`: Larger = more context, slower
- `TOP_K_RETRIEVAL`: More = better recall, slower
- `RERANK_TOP_K`: Final number of chunks used

## 🐛 Troubleshooting

### Services won't start
```bash
# Check Docker is running
docker ps

# View logs
./dev.sh logs

# Restart everything
./dev.sh restart
```

### Can't connect to API
```bash
# Check backend status
curl http://localhost:8000/health

# View backend logs
./dev.sh logs backend

# Restart backend
docker-compose restart backend
```

### OpenAI API errors
```bash
# Verify API key
cat .env | grep OPENAI_API_KEY

# Update and restart
nano .env
docker-compose restart backend
```

### Database issues
```bash
# Check database
./dev.sh shell-db

# Reset database
./dev.sh clean
./dev.sh start
```

## 📊 Monitoring

### Check System Health
```bash
# Live monitoring
./monitor.sh watch

# View statistics
./monitor.sh stats

# Check for errors
./monitor.sh errors
```

### View Logs
```bash
# All logs
./dev.sh logs

# Specific service
./dev.sh logs backend
./dev.sh logs frontend
```

### Performance Testing
```bash
# Run benchmarks
./benchmark.sh

# Test API
./test-api.sh

# Test RAG pipeline
./test-rag.sh
```

## 🎓 Learning Path

### Day 1: Setup & Basics
1. ✅ Install and run the application
2. ✅ Create an account
3. ✅ Upload a test document
4. ✅ Ask some questions
5. ✅ Explore the analytics dashboard

### Day 2: Understanding RAG
1. Read [RAG Pipeline Documentation](docs/rag-pipeline.md)
2. Experiment with different document types
3. Try various query types
4. Observe source citations

### Day 3: API Integration
1. Read [API Documentation](docs/api.md)
2. Test API endpoints with curl
3. Try the test scripts
4. Build a simple integration

### Week 2: Customization
1. Adjust RAG parameters
2. Customize the frontend
3. Add custom document types
4. Implement custom workflows

### Week 3: Production
1. Read [Deployment Guide](docs/deployment.md)
2. Setup production database
3. Configure cloud storage
4. Deploy to production

## 🔐 Security Checklist

Before going to production:

- [ ] Change SECRET_KEY in .env
- [ ] Use strong database passwords
- [ ] Enable HTTPS/TLS
- [ ] Configure firewall rules
- [ ] Setup backup strategy
- [ ] Enable audit logging
- [ ] Review CORS settings
- [ ] Implement rate limiting

## 📈 Performance Tips

### For Better Speed
- Enable Redis caching
- Use connection pooling
- Optimize chunk size
- Reduce TOP_K values

### For Better Accuracy
- Increase TOP_K_RETRIEVAL
- Use larger chunk sizes
- Enable query expansion
- Fine-tune prompts

### For Lower Costs
- Use gpt-3.5-turbo instead of gpt-4
- Cache frequently asked questions
- Batch document processing
- Optimize chunk overlap

## 🆘 Getting Help

### Documentation
- [README.md](README.md) - Project overview
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [docs/architecture.md](docs/architecture.md) - Architecture details
- [docs/rag-pipeline.md](docs/rag-pipeline.md) - RAG pipeline
- [docs/api.md](docs/api.md) - API reference
- [docs/deployment.md](docs/deployment.md) - Deployment guide

### Testing & Verification
- [SETUP_VERIFICATION.md](SETUP_VERIFICATION.md) - Verify installation
- [STATUS.md](STATUS.md) - Implementation status

### Scripts
- `./dev.sh help` - Development commands
- `./monitor.sh help` - Monitoring commands

### Support
- GitHub Issues: Report bugs
- Email: support@yourdomain.com
- Documentation: See `/docs` folder

## 🎉 Next Steps

Now that you're set up, here are some things to try:

1. **Upload Real Documents**
   - Company policies
   - Product documentation
   - Research papers
   - Meeting notes

2. **Test Different Queries**
   - Simple questions
   - Complex multi-part questions
   - Conceptual queries
   - Specific fact-finding

3. **Explore Features**
   - Conversation history
   - Source citations
   - Analytics dashboard
   - Document management

4. **Customize**
   - Adjust RAG parameters
   - Modify the UI
   - Add custom features
   - Integrate with your tools

5. **Deploy to Production**
   - Setup cloud infrastructure
   - Configure monitoring
   - Enable security features
   - Train your team

## 💡 Pro Tips

- **Start Small**: Upload a few documents first
- **Test Queries**: Try different question types
- **Monitor Performance**: Use the monitoring tools
- **Read Logs**: They contain valuable information
- **Experiment**: Adjust parameters and see what works
- **Backup Regularly**: Use `./dev.sh backup`

## 🌟 Success Metrics

You'll know you're successful when:

- ✅ Users can find answers quickly
- ✅ Responses include relevant sources
- ✅ Response time is under 5 seconds
- ✅ Accuracy is above 85%
- ✅ Users prefer it over manual search

## 📞 Contact

Questions? Issues? Feedback?

- **Documentation**: Check `/docs` folder first
- **Scripts**: Run with `--help` flag
- **Logs**: Check with `./monitor.sh logs`
- **Support**: support@yourdomain.com

---

**Ready to build something amazing? Let's go! 🚀**
