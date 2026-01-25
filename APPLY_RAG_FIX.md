# How to Apply the RAG Fix

## Current Status
✅ **Code changes are complete!** The fix is already in your files.

## What You Need to Do

### Step 1: Set Up the Environment (First Time Only)

Since you don't have a virtual environment set up yet, run:

```bash
./setup-local.sh
```

This will:
- Create a Python virtual environment
- Install all dependencies (including chromadb and sentence-transformers)
- Set up PostgreSQL and Redis
- Start the backend and frontend

**OR** if you prefer Docker:

```bash
docker-compose up --build -d
```

### Step 2: Upload Your Documents

Once the system is running, upload your Kinyarwanda documents:
- Go to http://localhost:3000
- Login (or create an account)
- Navigate to Documents section
- Upload `serivisi_zubutaka_kinyarwanda.txt`

### Step 3: Test the Fix

Ask the question that was failing:
```
Ni iki gikenewe kugira ngo nandikishe ubutaka?
```

**Expected Answer:**
```
- Icyangombwa cy'umwirondoro (Irangamuntu cyangwa Pasiporo)
- Inyandiko zerekana ko uri nyir'ubutaka
- Ibyemeza by'abatangabuhamya niba bikenewe
```

**Should NOT see:**
- ❌ "Description: Land Subdivision"
- ❌ "Ibisobanuro: Serivisi yo kugabanya..."
- ❌ Information about wrong services

## Alternative: Manual Setup

If you prefer to set up manually:

```bash
# 1. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 2. Install dependencies
cd backend
pip3 install -r requirements.txt
cd ..

# 3. Set up database (if needed)
# Follow instructions in setup-local.sh for PostgreSQL and Redis

# 4. Start Ollama (for local LLM)
ollama serve &
ollama pull aya:8b

# 5. Start backend
cd backend
source ../venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## What the Fix Does

The fix is already in these files:
- `backend/app/core/rag_orchestrator_local.py` - Main RAG logic
- `backend/app/core/document_processor.py` - Document chunking

When you run the system, it will automatically:
1. **Preprocess queries** - Maps "nandikishe" → "Kwandikisha Ubutaka"
2. **Filter chunks** - Removes information from wrong services
3. **Clean answers** - Removes descriptions, keeps only requested info

## Verification

After setup, verify the fix is working:

```bash
source venv/bin/activate
python3 test_rag_query.py
```

Or check the verification script:

```bash
./verify_rag_fix.sh
```

## Need Help?

See these guides:
- `QUICK_FIX_GUIDE.md` - Quick reference
- `RAG_FIX_SUMMARY.md` - Technical details
- `TEST_RAG_QUERIES.md` - Test cases
- `RAG_FIX_FLOW.md` - Visual diagram

## Summary

**You don't need to change any code!** The fix is already applied. Just:
1. Run `./setup-local.sh` (or use Docker)
2. Upload your documents
3. Test the queries

The system will automatically use the improved RAG logic.
