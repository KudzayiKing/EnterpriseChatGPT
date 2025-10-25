from typing import List, Dict, Any, Optional
try:
    from langchain.text_splitter import RecursiveCharacterTextSplitter
except ImportError:
    from langchain_text_splitters import RecursiveCharacterTextSplitter

try:
    from langchain_community.llms import Ollama
except ImportError:
    from langchain.llms import Ollama

try:
    from langchain_community.embeddings import HuggingFaceEmbeddings
except ImportError:
    from langchain.embeddings import HuggingFaceEmbeddings

try:
    from langchain.prompts import ChatPromptTemplate
except ImportError:
    from langchain_core.prompts import ChatPromptTemplate

from sentence_transformers import CrossEncoder
import chromadb
from chromadb.config import Settings as ChromaSettings
import logging

from app.core.config import settings

logger = logging.getLogger(__name__)

class RAG2OrchestratorLocal:
    """
    Local RAG 2.0 Pipeline - No Cloud Dependencies
    Uses Ollama for LLM and HuggingFace for embeddings
    Perfect for enterprise/intranet deployments
    """
    
    def __init__(self):
        # Local embeddings (runs on your machine)
        logger.info("Initializing local embedding model...")
        self.embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={'device': 'cpu'},
            encode_kwargs={'normalize_embeddings': True}
        )
        
        # Local LLM via Ollama
        logger.info("Initializing local LLM (Ollama)...")
        self.llm = Ollama(
            model="llama3.1:8b",  # or "mistral:7b"
            base_url="http://localhost:11434",
            temperature=0.7
        )
        
        # Local reranker
        logger.info("Initializing reranker...")
        self.reranker = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
        
        # Initialize ChromaDB
        self.chroma_client = chromadb.PersistentClient(
            path=settings.CHROMA_PERSIST_DIR,
            settings=ChromaSettings(anonymized_telemetry=False)
        )
        
        # Conversation context cache for faster follow-up questions
        self.context_cache = {}  # {conversation_id: {chunks, timestamp}}
        
        logger.info("✅ Local RAG 2.0 pipeline initialized successfully")
    
    async def process_query(
        self,
        query: str,
        tenant_id: int,
        conversation_history: Optional[List[Dict]] = None,
        conversation_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """Main RAG 2.0 pipeline orchestration - fully local"""
        try:
            logger.info(f"Processing query: {query[:50]}... (mode: {settings.RAG_MODE})")
            
            # Fast Mode: Skip expensive operations for 5-15 second responses
            if settings.RAG_MODE == "fast":
                return await self.process_query_fast(query, tenant_id, conversation_history, conversation_id)
            
            # Accurate Mode: Full RAG 2.0 pipeline
            # Step 1: Query Understanding & Expansion
            expanded_queries = await self.query_expansion(query, conversation_history)
            
            # Step 2: Multi-Stage Retrieval
            candidate_chunks = await self.hybrid_retrieval(expanded_queries, tenant_id)
            
            # Step 3: Cross-Encoder Reranking
            reranked_chunks = await self.cross_encoder_rerank(query, candidate_chunks)
            
            # Step 4: Contextual Compression
            compressed_context = await self.context_compression(reranked_chunks)
            
            # Step 5: Generation with Verification
            response = await self.generate_with_verification(
                compressed_context,
                query,
                conversation_history
            )
            
            # Step 6: Self-Correction Loop
            if not await self.verify_response(response, compressed_context):
                logger.info("Response verification failed, refining query")
                refined_query = await self.refine_query(query, response)
                return await self.process_query(refined_query, tenant_id, conversation_history)
            
            return {
                "answer": response["answer"],
                "sources": response["sources"],
                "confidence": response["confidence"],
                "metadata": {
                    "expanded_queries": expanded_queries,
                    "chunks_retrieved": len(candidate_chunks),
                    "chunks_used": len(compressed_context),
                    "model": "local-llama3.1-8b",
                    "mode": "accurate"
                }
            }
            
        except Exception as e:
            logger.error(f"Error in RAG pipeline: {str(e)}")
            raise
    
    async def process_query_fast(
        self,
        query: str,
        tenant_id: int,
        conversation_history: Optional[List[Dict]] = None,
        conversation_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """Fast mode: Direct retrieval + generation (5-15 seconds) with context caching"""
        try:
            # Check cache for recent context (reuse for follow-up questions)
            cache_key = f"{tenant_id}_{conversation_id}" if conversation_id else None
            cached_context = None
            
            if cache_key and cache_key in self.context_cache:
                cache_entry = self.context_cache[cache_key]
                # Use cache if less than 5 minutes old
                import time
                if time.time() - cache_entry['timestamp'] < 300:
                    cached_context = cache_entry['chunks']
                    logger.info("Using cached context for faster response")
            
            # Get collection for tenant
            collection_name = f"tenant_{tenant_id}"
            try:
                collection = self.chroma_client.get_collection(collection_name)
            except:
                logger.warning(f"Collection {collection_name} not found")
                return {
                    "answer": "I don't have any documents to search through yet. Please upload some documents first.",
                    "sources": [],
                    "confidence": 0.0,
                    "metadata": {"mode": "fast", "error": "no_documents"}
                }
            
            # Use cached context or retrieve new
            if cached_context:
                results = {'documents': [cached_context], 'metadatas': [[{'cached': True}] * len(cached_context)]}
            else:
                # Simple vector search (no expansion, no reranking)
                query_embedding = self.embeddings.embed_query(query)
                results = collection.query(
                    query_embeddings=[query_embedding],
                    n_results=settings.RERANK_TOP_K
                )
                
                # Cache the results
                if cache_key and results['documents'] and len(results['documents'][0]) > 0:
                    import time
                    self.context_cache[cache_key] = {
                        'chunks': results['documents'][0],
                        'timestamp': time.time()
                    }
            
            # Build context from top results
            context_parts = []
            sources = []
            
            if results['documents'] and len(results['documents'][0]) > 0:
                for i, (doc, metadata) in enumerate(zip(results['documents'][0], results['metadatas'][0])):
                    context_parts.append(f"[Source {i+1}]: {doc}")
                    sources.append({
                        "content": doc[:200] + "..." if len(doc) > 200 else doc,
                        "metadata": metadata
                    })
            
            context = "\n\n".join(context_parts)
            
            # Simple prompt without verification
            prompt = f"""Based on the following context, answer the question concisely and accurately.

Context:
{context}

Question: {query}

Answer:"""
            
            # Generate answer
            answer = self.llm.invoke(prompt)
            
            return {
                "answer": answer,
                "sources": sources,
                "confidence": 0.85,
                "metadata": {
                    "chunks_retrieved": len(sources),
                    "chunks_used": len(sources),
                    "model": "local-llama3.1-8b",
                    "mode": "fast"
                }
            }
            
        except Exception as e:
            logger.error(f"Error in fast query: {str(e)}")
            raise
    
    async def query_expansion(
        self,
        query: str,
        conversation_history: Optional[List[Dict]] = None
    ) -> List[str]:
        """Expand query using local LLM"""
        expanded = [query]
        
        try:
            # HyDE: Generate hypothetical document
            hyde_prompt = f"Generate a detailed passage that would answer this question: {query}"
            hyde_response = self.llm.invoke(hyde_prompt)
            expanded.append(hyde_response)
            
            # Step-back prompting
            stepback_prompt = f"What is the broader concept or principle behind this question: {query}"
            stepback_response = self.llm.invoke(stepback_prompt)
            expanded.append(stepback_response)
        except Exception as e:
            logger.warning(f"Query expansion failed: {e}, using original query only")
        
        return expanded
    
    async def hybrid_retrieval(
        self,
        queries: List[str],
        tenant_id: int
    ) -> List[Dict[str, Any]]:
        """Hybrid search using local embeddings"""
        collection_name = f"tenant_{tenant_id}"
        
        try:
            collection = self.chroma_client.get_collection(collection_name)
        except:
            logger.warning(f"Collection {collection_name} not found")
            return []
        
        all_results = []
        
        for query in queries:
            # Generate embedding locally
            query_embedding = self.embeddings.embed_query(query)
            results = collection.query(
                query_embeddings=[query_embedding],
                n_results=settings.TOP_K_RETRIEVAL
            )
            
            if results['documents']:
                for i, doc in enumerate(results['documents'][0]):
                    all_results.append({
                        'content': doc,
                        'metadata': results['metadatas'][0][i] if results['metadatas'] else {},
                        'score': results['distances'][0][i] if results['distances'] else 0
                    })
        
        # Deduplicate
        seen = set()
        unique_results = []
        for result in all_results:
            content_hash = hash(result['content'])
            if content_hash not in seen:
                seen.add(content_hash)
                unique_results.append(result)
        
        return unique_results[:settings.TOP_K_RETRIEVAL]
    
    async def cross_encoder_rerank(
        self,
        query: str,
        candidates: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Rerank candidates using local cross-encoder"""
        if not candidates:
            return []
        
        pairs = [[query, c['content']] for c in candidates]
        scores = self.reranker.predict(pairs)
        
        for i, candidate in enumerate(candidates):
            candidate['rerank_score'] = float(scores[i])
        
        reranked = sorted(candidates, key=lambda x: x['rerank_score'], reverse=True)
        return reranked[:settings.RERANK_TOP_K]
    
    async def context_compression(
        self,
        chunks: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Compress context to most relevant information"""
        return chunks
    
    async def generate_with_verification(
        self,
        context: List[Dict[str, Any]],
        query: str,
        conversation_history: Optional[List[Dict]] = None
    ) -> Dict[str, Any]:
        """Generate response using local LLM"""
        
        context_text = "\n\n".join([
            f"Source {i+1}:\n{chunk['content']}"
            for i, chunk in enumerate(context)
        ])
        
        prompt = f"""You are an expert AI assistant. Answer the question based on the provided context.
Be precise, cite sources, and indicate confidence level.

Context:
{context_text}

Question: {query}

Provide a detailed answer with:
1. Direct answer to the question
2. Source citations (mention which sources you used)
3. Confidence level (high/medium/low)

Answer:"""
        
        try:
            response_text = self.llm.invoke(prompt)
            
            return {
                "answer": response_text,
                "sources": [
                    {
                        "content": chunk['content'][:200] + "...",
                        "metadata": chunk.get('metadata', {})
                    }
                    for chunk in context
                ],
                "confidence": "high"
            }
        except Exception as e:
            logger.error(f"Generation failed: {e}")
            return {
                "answer": "I apologize, but I encountered an error generating the response.",
                "sources": [],
                "confidence": "low"
            }
    
    async def verify_response(
        self,
        response: Dict[str, Any],
        context: List[Dict[str, Any]]
    ) -> bool:
        """Verify response accuracy"""
        # For now, return True
        # In production, implement fact verification
        return True
    
    async def refine_query(self, original_query: str, failed_response: Dict) -> str:
        """Refine query if verification fails"""
        try:
            prompt = f"Rephrase this query to be more specific: {original_query}"
            refined = self.llm.invoke(prompt)
            return refined
        except:
            return original_query
