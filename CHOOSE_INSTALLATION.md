# 🚀 Choose Your Installation Method

## Quick Decision Guide

Answer these questions to choose the best installation method:

### Question 1: Do you have Docker installed?
- **Yes** → Use Docker (Option A)
- **No** → Continue to Question 2

### Question 2: Are you willing to install Docker?
- **Yes** → Use Docker (Option A) - Recommended
- **No** → Use Local Setup (Option B)

### Question 3: What's your primary goal?
- **Just want to try it** → Docker (Option A)
- **Active development** → Local Setup (Option B)
- **Production deployment** → Docker (Option A)

---

## Option A: Docker Installation 🐳

**Best for:** Most users, production, easy setup

### Quick Start
```bash
# 1. Install Docker Desktop
brew install --cask docker
open /Applications/Docker.app

# 2. Wait for Docker to start (whale icon in menu bar)

# 3. Run setup
./setup.sh

# 4. Add OpenAI API key
nano .env

# 5. Restart and open
docker-compose restart
open http://localhost:3000
```

**Time:** 5-10 minutes  
**Difficulty:** ⭐ Easy

---

## Option B: Local Setup 💻

**Best for:** Developers, no Docker, direct code access

### Quick Start
```bash
# 1. Run automated local setup
./setup-local.sh

# 2. Add OpenAI API key
nano backend/.env

# 3. Start services
./start-local.sh

# 4. Open application
open http://localhost:3000
```

**Time:** 10-15 minutes  
**Difficulty:** ⭐⭐ Moderate

---

## Still Not Sure?

### Choose Docker if:
- ✅ You want the easiest setup
- ✅ You're deploying to production
- ✅ You want isolated environments
- ✅ You don't want to install many dependencies

### Choose Local if:
- ✅ You can't or don't want to install Docker
- ✅ You're actively developing/debugging
- ✅ You want faster code iteration
- ✅ You prefer direct access to services

---

## What You Need

### For Docker:
- Docker Desktop (we'll help you install it)
- OpenAI API key
- 8GB RAM
- 10GB disk space

### For Local:
- macOS (you have this ✅)
- Homebrew (we'll install it)
- OpenAI API key
- 8GB RAM
- 5GB disk space

---

## Installation Commands

### Docker Path
```bash
# Install Docker
brew install --cask docker
open /Applications/Docker.app

# Setup application
./setup.sh
nano .env  # Add API key
docker-compose restart
open http://localhost:3000
```

### Local Path
```bash
# Setup everything
./setup-local.sh
nano backend/.env  # Add API key
./start-local.sh
open http://localhost:3000
```

---

## After Installation

Both methods give you:
- ✅ Full application running
- ✅ Frontend at http://localhost:3000
- ✅ Backend at http://localhost:8000
- ✅ API docs at http://localhost:8000/docs

Next steps:
1. Create an account
2. Upload documents
3. Start chatting
4. Read [GETTING_STARTED.md](GETTING_STARTED.md)

---

## Need Help?

- **Docker Installation**: See [INSTALLATION_OPTIONS.md](INSTALLATION_OPTIONS.md)
- **Local Setup**: Run `./setup-local.sh` and follow prompts
- **General Help**: Check [GETTING_STARTED.md](GETTING_STARTED.md)
- **Troubleshooting**: See [SETUP_VERIFICATION.md](SETUP_VERIFICATION.md)

---

## My Recommendation

**For you right now:** I recommend **Option B (Local Setup)** since you don't have Docker installed yet.

Run this command:
```bash
./setup-local.sh
```

It will automatically install everything you need and set up the application.

Then:
```bash
nano backend/.env  # Add your OpenAI API key
./start-local.sh
open http://localhost:3000
```

**That's it!** 🎉

---

**Ready to start?** Pick your option and run the commands above!
