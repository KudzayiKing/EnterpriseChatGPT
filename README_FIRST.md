# 👋 READ THIS FIRST

## You Don't Have Docker? Perfect!

I've created **two installation methods** for you:

---

## 🎯 Recommended for You: Local Setup

Since you don't have Docker installed, use the **Local Setup** method:

```bash
./setup-local.sh
```

This single command will:
- ✅ Install all required dependencies (Python, Node.js, PostgreSQL, Redis)
- ✅ Set up the backend and frontend
- ✅ Create all configuration files
- ✅ Prepare the database
- ✅ Make everything ready to run

**Then:**
```bash
# Add your OpenAI API key
nano backend/.env

# Start the application
./start-local.sh

# Open in browser
open http://localhost:3000
```

**That's it!** No Docker needed.

---

## 📚 What You Have

This is a **complete Enterprise RAG 2.0 Chat Application** with:

- 🤖 Advanced AI chat with RAG 2.0 pipeline
- 📄 Document processing (PDF, DOCX, PPTX, Excel, HTML, TXT)
- 💬 Real-time chat interface
- 📊 Analytics dashboard
- 🔐 User authentication
- 🏢 Multi-tenancy support
- 📖 Comprehensive documentation
- 🛠️ Helper scripts for everything

---

## 🚀 Quick Start Guide

### Step 1: Run Setup (10 minutes)
```bash
./setup-local.sh
```

Wait for it to complete. It will install everything automatically.

### Step 2: Add OpenAI API Key
```bash
nano backend/.env
```

Find this line:
```
OPENAI_API_KEY=your_openai_api_key_here
```

Replace with your actual key:
```
OPENAI_API_KEY=sk-your-actual-key-here
```

Save and exit (Ctrl+X, then Y, then Enter)

### Step 3: Start the Application
```bash
./start-local.sh
```

### Step 4: Open in Browser
```bash
open http://localhost:3000
```

### Step 5: Create Account & Start Using
1. Sign up with your email
2. Upload a document
3. Ask questions
4. Get AI-powered answers!

---

## 📖 Documentation

**Start Here:**
- [START_HERE.md](START_HERE.md) - Main entry point
- [CHOOSE_INSTALLATION.md](CHOOSE_INSTALLATION.md) - Installation options
- [INSTALLATION_OPTIONS.md](INSTALLATION_OPTIONS.md) - Detailed comparison

**Learn More:**
- [GETTING_STARTED.md](GETTING_STARTED.md) - Comprehensive guide
- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - What this application does
- [docs/](docs/) - Technical documentation

---

## 🛠️ Useful Commands

### Start/Stop
```bash
./start-local.sh    # Start all services
./stop-local.sh     # Stop all services
```

### Testing
```bash
./test-api.sh       # Test API endpoints
./test-rag.sh       # Test RAG pipeline
```

### Monitoring
```bash
# Check if services are running
lsof -i :8000       # Backend
lsof -i :3000       # Frontend
```

---

## 🆘 Troubleshooting

### Setup fails?
```bash
# Check Homebrew
brew --version

# Update Homebrew
brew update

# Try setup again
./setup-local.sh
```

### Services won't start?
```bash
# Check PostgreSQL
brew services list

# Restart PostgreSQL
brew services restart postgresql@15

# Restart Redis
brew services restart redis
```

### Can't connect to API?
```bash
# Check if backend is running
curl http://localhost:8000/health

# Check backend logs
tail -f backend/logs/*.log
```

---

## ✅ Success Checklist

After setup, verify:
- [ ] `./setup-local.sh` completed successfully
- [ ] Added OpenAI API key to `backend/.env`
- [ ] `./start-local.sh` started both services
- [ ] http://localhost:3000 loads in browser
- [ ] http://localhost:8000/health returns `{"status":"healthy"}`
- [ ] Can create an account
- [ ] Can upload a document
- [ ] Can chat and get responses

---

## 🎉 You're All Set!

Once setup is complete, you'll have a **production-ready AI chat application** running locally.

**Next steps:**
1. Run `./setup-local.sh`
2. Add your OpenAI API key
3. Run `./start-local.sh`
4. Open http://localhost:3000
5. Start building!

---

## 💡 Pro Tips

1. **Keep services running** - Use `./start-local.sh` in a dedicated terminal
2. **Check logs** - If something fails, check the terminal output
3. **Read docs** - [GETTING_STARTED.md](GETTING_STARTED.md) has everything
4. **Test early** - Use `./test-api.sh` to verify everything works
5. **Backup** - Your data is in `backend/uploads/` and `backend/chroma_db/`

---

## 📞 Need Help?

1. Check [INSTALLATION_OPTIONS.md](INSTALLATION_OPTIONS.md)
2. Read [SETUP_VERIFICATION.md](SETUP_VERIFICATION.md)
3. See [GETTING_STARTED.md](GETTING_STARTED.md)
4. Review error messages in terminal

---

## 🚀 Ready to Start?

Run this now:
```bash
./setup-local.sh
```

Then follow the prompts. It will guide you through everything!

**Let's build something amazing! 🎊**
