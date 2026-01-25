#!/bin/bash

cd backend
source venv/bin/activate

python3 << 'EOF'
import chromadb
from chromadb.config import Settings as ChromaSettings

# Connect to ChromaDB
client = chromadb.PersistentClient(
    path="./chroma_db",
    settings=ChromaSettings(anonymized_telemetry=False)
)

# List all collections
collections = client.list_collections()
print(f"\n=== Found {len(collections)} collections ===")

for coll in collections:
    print(f"\nCollection: {coll.name}")
    print(f"  Count: {coll.count()}")
    
    # Get a sample of documents
    if coll.count() > 0:
        results = coll.get(limit=2)
        print(f"  Sample documents:")
        for i, doc in enumerate(results['documents'][:2]):
            print(f"    Doc {i+1}: {doc[:100]}...")
            if results['metadatas']:
                print(f"    Metadata: {results['metadatas'][i]}")

# Test a query on tenant_3 (your user's tenant)
print("\n=== Testing query on tenant_3 ===")
try:
    collection = client.get_collection("tenant_3")
    print(f"Collection tenant_3 has {collection.count()} documents")
    
    # Try a simple query
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')
    
    query = "Ni iki gikenewe kugira ngo nandikishe ubutaka?"
    query_embedding = model.encode(query).tolist()
    
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=3
    )
    
    print(f"\nQuery results for: '{query}'")
    print(f"Found {len(results['documents'][0])} results")
    for i, doc in enumerate(results['documents'][0]):
        print(f"\nResult {i+1}:")
        print(f"  Content: {doc[:200]}...")
        if results['distances']:
            print(f"  Distance: {results['distances'][0][i]}")
        
except Exception as e:
    print(f"Error: {e}")

EOF
