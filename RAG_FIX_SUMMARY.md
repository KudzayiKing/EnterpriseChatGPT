# RAG System Fix Summary

## Problem
The RAG system was returning incorrect responses:
1. **Wrong Service**: Query "Ni iki gikenewe kugira ngo nandikishe ubutaka?" (What is required to register land?) was returning information about "Kugabanya Ubutaka" (Land Subdivision) instead of "Kwandikisha Ubutaka" (Land Registration)
2. **Unwanted Description**: Responses included "Description:" or "Ibisobanuro:" sections even when only requirements were asked

## Root Causes
1. **Poor Query-Document Matching**: The embedding model wasn't matching the query verb "nandikishe" (register) with the service title "Kwandikisha Ubutaka"
2. **LLM Not Following Instructions**: The prompt told the LLM not to include descriptions, but it still did
3. **No Post-Processing**: No cleanup of the generated answer to remove unwanted sections

## Solutions Implemented

### 1. Query Preprocessing (`_preprocess_query`)
**File**: `backend/app/core/rag_orchestrator_local.py`

Added intelligent query expansion that maps common verbs to service names:
- "nandikishe/kwandikisha" → adds "Kwandikisha Ubutaka"
- "kugabanya" → adds "Kugabanya Ubutaka"
- "kwimura" → adds "Kwimura Izina"
- etc.

This helps the embedding model find the correct service section.

### 2. Improved Prompt
**File**: `backend/app/core/rag_orchestrator_local.py`

Enhanced the prompt with:
- Explicit examples: "If asked 'Ni iki gikenewe kugira ngo nandikishe ubutaka?' - look for 'Kwandikisha Ubutaka' section"
- Numbered rules for clarity
- Specific instructions to NOT mix information from different services
- Clear instructions to extract only the requested field (requirements, price, or time)

### 3. Answer Post-Processing (`_clean_answer`)
**File**: `backend/app/core/rag_orchestrator_local.py`

Added post-processing to clean the LLM's response:
- Detects query type (requirements, price, time)
- Removes "Description:" or "Ibisobanuro:" sections using regex
- Extracts only the relevant section (e.g., "Ibikenewe:" for requirements)
- Removes service names that don't match the query

### 4. Better Document Chunking
**File**: `backend/app/core/document_processor.py`

Improved the text splitter separators to include `"\n**"` to better preserve service sections that use bold markdown formatting.

### 5. Chunk Filtering (`_filter_relevant_chunks`)
**File**: `backend/app/core/rag_orchestrator_local.py`

Added intelligent filtering of retrieved chunks:
- Retrieves more chunks initially (2x the normal amount)
- Scores each chunk based on service name match
- Penalizes chunks from wrong services
- Returns only the top-scored chunks to the LLM

This ensures the LLM sees only information from the correct service.

## Testing

Run the test script to verify the fix:
```bash
python test_rag_query.py
```

Expected output for "Ni iki gikenewe kugira ngo nandikishe ubutaka?":
```
- Icyangombwa cy'umwirondoro (Irangamuntu cyangwa Pasiporo)
- Inyandiko zerekana ko uri nyir'ubutaka (urugero: ibaruwa y'akagari/umurenge, amasezerano y'igurisha)
- Ibyemeza by'abatangabuhamya niba bikenewe
```

## Files Modified
1. `backend/app/core/rag_orchestrator_local.py` - Main RAG logic
2. `backend/app/core/document_processor.py` - Document chunking
3. `test_rag_query.py` - New test script (created)

## Documentation Created
1. `RAG_FIX_SUMMARY.md` - This file (overview of changes)
2. `RAG_FIX_FLOW.md` - Visual flow diagram showing before/after
3. `TEST_RAG_QUERIES.md` - Test queries and expected results

## Next Steps
1. Test with the actual system
2. If documents need to be re-indexed with the new chunking strategy, run:
   ```bash
   ./reindex-documents.sh
   ```
3. Monitor logs to see the query preprocessing in action
4. Adjust the `_preprocess_query` mapping if other services have similar issues
