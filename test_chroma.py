#!/usr/bin/env python3
"""Test script to check what's in ChromaDB"""

import chromadb
from chromadb.config import Settings as ChromaSettings
from sentence_transformers import SentenceTransformer

# Initialize ChromaDB
chroma_client = chromadb.PersistentClient(
    path="./backend/chroma_db",
    settings=ChromaSettings(anonymized_telemetry=False)
)

# Initialize embeddings
model = SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')

# List all collections
collections = chroma_client.list_collections()
print(f"Found {len(collections)} collections:")
for coll in collections:
    print(f"  - {coll.name}")

# Try to get tenant_3 collection (your user)
try:
    collection = chroma_client.get_collection("tenant_3")
    print(f"\n✓ Collection 'tenant_3' found")
    print(f"  Documents count: {collection.count()}")
    
    # Test query
    query = "Ni iki gikenewe kugira ngo nandikishe ubutaka?"
    print(f"\nQuerying: {query}")
    
    query_embedding = model.encode(query).tolist()
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=3
    )
    
    print(f"\nResults found: {len(results['documents'][0])}")
    for i, (doc, metadata) in enumerate(zip(results['documents'][0], results['metadatas'][0])):
        print(f"\n--- Result {i+1} ---")
        print(f"Content: {doc[:200]}...")
        print(f"Metadata: {metadata}")
        
except Exception as e:
    print(f"\n✗ Error: {e}")
