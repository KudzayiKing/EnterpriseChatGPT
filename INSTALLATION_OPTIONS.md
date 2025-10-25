# Installation Options

You have two ways to run Enterprise RAG 2.0:

## Option 1: Docker (Recommended) ⭐

**Pros:**
- ✅ Easiest setup
- ✅ No dependency conflicts
- ✅ Matches production environment
- ✅ Easy to reset/clean

**Installation:**

### Step 1: Install Docker Desktop for Mac

**Using Homebrew:**
```bash
brew install --cask docker
open /Applications/Docker.app
```

**Or download directly:**
- Go to: https://www.docker.com/products/docker-desktop
- Download Docker Desktop for Mac (Apple Silicon or Intel)
- Install and start Docker Desktop
- Wait for the whale icon to appear in your menu bar

### Step 2: Run Setup
```bash
./setup.sh
```

### Step 3: Configure
```bash
nano .env
# Add your OpenAI API key: OPENAI_API_KEY=sk-...
```

### Step 4: Restart
```bash
docker-compose restart
```

### Step 5: Access
```bash
open http://localhost:3000
```

---

## Option 2: Local Development (No Docker)

**Pros:**
- ✅ No Docker needed
- ✅ Direct access to code
- ✅ Faster iteration for development

**Cons:**
- ⚠️ More dependencies to install
- ⚠️ Potential version conflicts
- ⚠️ Manual service management

**Installation:**

### Step 1: Run Local Setup
```bash
./setup-local.sh
```

This will automatically:
- Install Homebrew (if needed)
- Install Python 3.11
- Install Node.js 20
- Install PostgreSQL 15
- Install Redis 7
- Create database
- Setup backend virtual environment
- Install all dependencies
- Create configuration files

### Step 2: Configure
```bash
nano backend/.env
# Add your OpenAI API key: OPENAI_API_KEY=sk-...
```

### Step 3: Start Services
```bash
./start-local.sh
```

### Step 4: Access
```bash
open http://localhost:3000
```

### To Stop Services
```bash
./stop-local.sh
```

---

## Quick Comparison

| Feature | Docker | Local |
|---------|--------|-------|
| Setup Time | 5 min | 10-15 min |
| Dependencies | Just Docker | Python, Node, PostgreSQL, Redis |
| Isolation | ✅ Complete | ❌ Shares system |
| Production Match | ✅ Exact | ⚠️ Similar |
| Development Speed | Good | Faster |
| Cleanup | Easy | Manual |

---

## Recommendation

**For most users:** Use Docker (Option 1)
- Easier to get started
- Fewer things to go wrong
- Matches production environment

**For active development:** Use Local (Option 2)
- Faster code iteration
- Direct debugging
- No container overhead

---

## What to Do Now

### If you want Docker:
```bash
# Install Docker Desktop
brew install --cask docker
open /Applications/Docker.app

# Wait for Docker to start, then:
./setup.sh
nano .env  # Add OpenAI API key
docker-compose restart
open http://localhost:3000
```

### If you want Local:
```bash
# Run local setup
./setup-local.sh

# Add OpenAI API key
nano backend/.env

# Start services
./start-local.sh

# Open application
open http://localhost:3000
```

---

## Troubleshooting

### Docker Issues
```bash
# Check if Docker is running
docker ps

# If not, start Docker Desktop from Applications
open /Applications/Docker.app
```

### Local Issues
```bash
# Check services
brew services list

# Restart PostgreSQL
brew services restart postgresql@15

# Restart Redis
brew services restart redis

# Check logs
tail -f backend/logs/*.log
```

---

## Next Steps

After installation:
1. ✅ Create an account at http://localhost:3000
2. ✅ Upload a test document
3. ✅ Ask questions in chat
4. ✅ Explore analytics dashboard
5. ✅ Read [GETTING_STARTED.md](GETTING_STARTED.md)

---

## Need Help?

- **Docker Installation**: https://docs.docker.com/desktop/install/mac-install/
- **Local Setup Issues**: Check [SETUP_VERIFICATION.md](SETUP_VERIFICATION.md)
- **General Help**: See [GETTING_STARTED.md](GETTING_STARTED.md)

---

**Choose your path and let's get started! 🚀**
