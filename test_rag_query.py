#!/usr/bin/env python3
"""Test RAG query to debug retrieval issues"""

import asyncio
import sys
sys.path.insert(0, 'backend')

from app.core.rag_orchestrator_local import RAG2OrchestratorLocal
from app.core.config import settings

async def test_query():
    """Test the problematic query"""
    
    # Initialize RAG
    rag = RAG2OrchestratorLocal()
    
    # Test query
    query = "Ni iki gikenewe kugira ngo nandikishe ubutaka?"
    tenant_id = 1
    
    print(f"\n{'='*60}")
    print(f"Testing Query: {query}")
    print(f"{'='*60}\n")
    
    # Process query
    result = await rag.process_query(query, tenant_id)
    
    print(f"\n{'='*60}")
    print("ANSWER:")
    print(f"{'='*60}")
    print(result['answer'])
    
    print(f"\n{'='*60}")
    print("SOURCES:")
    print(f"{'='*60}")
    for i, source in enumerate(result['sources'], 1):
        print(f"\nSource {i}:")
        print(source['content'])
        print(f"Metadata: {source['metadata']}")
    
    print(f"\n{'='*60}")
    print("METADATA:")
    print(f"{'='*60}")
    print(result['metadata'])

if __name__ == "__main__":
    asyncio.run(test_query())
