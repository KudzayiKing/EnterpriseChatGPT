# Performance Optimization Guide

## Current Optimizations Applied ✅

### 1. Reduced Retrieval (Fastest Impact)
- **TOP_K_RETRIEVAL**: 15 → 5 (retrieve fewer chunks)
- **RERANK_TOP_K**: 8 → 3 (use fewer chunks in answer)
- **Impact**: ~30-40% faster retrieval

### 2. Optimized LLM Settings
- **Temperature**: 0.7 → 0.3 (more focused, less sampling)
- **num_predict**: Added limit of 256 tokens (shorter responses)
- **top_k**: 10 (reduced sampling space)
- **top_p**: 0.9 (nucleus sampling)
- **Impact**: ~20-30% faster generation

### 3. Already Using Fast Mode
- No query expansion
- No reranking
- No verification loops
- Direct retrieval + generation

## Expected Performance

**Before**: 17 seconds
**After**: 8-12 seconds (50% improvement)

## Additional Optimizations (If Still Too Slow)

### Option 1: Use Smaller Model
Replace Llama 3.1 8B with a smaller model:
```bash
ollama pull llama3.2:3b  # Much faster, slightly lower quality
```

Update config:
```python
OLLAMA_MODEL: str = "llama3.2:3b"
```
**Impact**: 3-5 seconds response time

### Option 2: GPU Acceleration
If you have a Mac with Apple Silicon:
- Ollama automatically uses Metal (GPU)
- Check: `ollama ps` to see if GPU is being used
- **Impact**: 2-4x faster

### Option 3: Reduce Context Further
```python
TOP_K_RETRIEVAL: int = 3  # Even fewer chunks
RERANK_TOP_K: int = 2
```
**Impact**: 6-8 seconds, but may reduce answer quality

### Option 4: Cache Embeddings
The embedding model loads on every request. We can cache it:
- Already implemented in the code
- Embeddings are reused across requests

### Option 5: Async Processing
Stream the response as it's generated:
- Show partial answers while generating
- Perceived speed improvement
- User sees response immediately

### Option 6: Pre-compute Common Queries
Cache answers for frequently asked questions:
- "What is the price for land registration?" → cached
- First request: 10 seconds
- Subsequent requests: <1 second

## Monitoring Performance

Check what's taking time:
```bash
tail -f backend.log | grep "Processing query"
```

Look for:
- Query processing time
- Retrieval time
- Generation time

## Hardware Recommendations

**Current Setup**: CPU-only inference
**Recommended**:
- Mac M1/M2/M3: Already using GPU (Metal)
- Linux: NVIDIA GPU with CUDA
- Windows: NVIDIA GPU with CUDA

**With GPU**: 2-5 seconds response time

## Trade-offs

| Optimization | Speed Gain | Quality Impact |
|-------------|------------|----------------|
| Fewer chunks | High | Low |
| Smaller model | Very High | Medium |
| Lower temperature | Low | Low |
| Shorter responses | Medium | Medium |
| GPU | Very High | None |

## Recommended Settings for Demo

For client demo, prioritize speed:
```python
TOP_K_RETRIEVAL: int = 3
RERANK_TOP_K: int = 2
OLLAMA_MODEL: str = "llama3.2:3b"  # If available
num_predict: int = 200
```

**Expected**: 5-8 seconds

## Testing

After changes, restart backend:
```bash
pkill -f uvicorn
cd backend && source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
```

Test query:
```
"What is the price for land registration?"
```

Time it and check logs for bottlenecks.
