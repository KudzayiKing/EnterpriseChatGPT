# Test Queries for RAG System

## Land Registration (Kwandikisha Ubutaka)

### Requirements Query
**Kinyarwanda**: Ni iki gikenewe kugira ngo nandikishe ubutaka?
**Expected Answer**:
- Icyangombwa cy'umwirondoro (Irangamuntu cyangwa Pasiporo)
- Inyandiko zerekana ko uri nyir'ubutaka (urugero: ibaruwa y'akagari/umurenge, amasezerano y'igurisha)
- Ibyemeza by'abatangabuhamya niba bikenewe

### Price Query
**Kinyarwanda**: Ni amafaranga angahe yo kwandikisha ubutaka?
**Expected Answer**: Amafaranga 5,000 y'u Rwanda

### Time Query
**Kinyarwanda**: Ni igihe kingana iki cyo kwandikisha ubutaka?
**Expected Answer**: Iminsi 7-14 y'akazi

## Land Subdivision (Kugabanya Ubutaka)

### Requirements Query
**Kinyarwanda**: Ni iki gikenewe kugira ngo ngabanya ubutaka?
**Expected Answer**:
- Icyangombwa cy'ubutaka cy'umwimerere
- Gahunda yo kugabanya yemewe n'umupima
- Kwishyura amafaranga yo kugabanya

### Price Query
**Kinyarwanda**: Ni amafaranga angahe yo kugabanya ubutaka?
**Expected Answer**: Amafaranga 10,000 y'u Rwanda kuri buri gice

## Land Transfer - Sale (Kwimura Izina - Igurisha)

### Requirements Query
**Kinyarwanda**: Ni iki gikenewe kugira ngo nimure izina ku butaka?
**Expected Answer**:
- Icyangombwa cy'ubutaka cy'uwagurisha gifite agaciro
- Amasezerano y'igurisha yashyizweho umukono n'impande zombi kandi yemejwe n'umwanditsi w'ibanze
- Kopi z'irangamuntu z'uwagurisha n'uwaguze
- Icyemeza cy'kwishyura amafaranga yo kwimura izina

## Testing Commands

### Test Single Query
```bash
python test_rag_query.py
```

### Test via API (if backend is running)
```bash
curl -X POST http://localhost:8000/api/v1/chat/query \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "query": "Ni iki gikenewe kugira ngo nandikishe ubutaka?",
    "conversation_id": null
  }'
```

### Check Logs
```bash
tail -f backend.log | grep -E "(query|Retrieved|Context)"
```

## What to Look For

### Good Signs ✅
- Answer contains ONLY the requirements list
- No "Ibisobanuro:" or "Description:" section
- No mention of wrong services (e.g., "Kugabanya" when asking about "Kwandikisha")
- Answer is in the same language as the question
- Bullet points are used for lists

### Bad Signs ❌
- Answer includes description/definition
- Answer mixes information from multiple services
- Answer is in wrong language
- Answer is too verbose or includes unnecessary context
- Wrong service information is returned

## Debugging

If you see wrong results:

1. Check the logs for query preprocessing:
   ```
   Original query: Ni iki gikenewe kugira ngo nandikishe ubutaka?
   Processed query: Ni iki gikenewe kugira ngo nandikishe ubutaka? Kwandikisha Ubutaka
   ```

2. Check retrieved chunks in sources

3. Check if documents need re-indexing:
   ```bash
   ./reindex-documents.sh
   ```

4. Verify Ollama is running:
   ```bash
   curl http://localhost:11434/api/tags
   ```
