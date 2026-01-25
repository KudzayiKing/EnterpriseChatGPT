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
from app.core.kinyacolbert_embeddings import KinyaColBERTEmbeddings

logger = logging.getLogger(__name__)

class RAG2OrchestratorLocal:
    """
    Local RAG 2.0 Pipeline - No Cloud Dependencies
    Uses Ollama for LLM and HuggingFace for embeddings
    Perfect for enterprise/intranet deployments
    """
    
    def __init__(self):
        # Local embeddings - Use KinyaColBERT for superior Kinyarwanda semantic search
        use_kinyacolbert = getattr(settings, 'USE_KINYACOLBERT', True)
        
        if use_kinyacolbert:
            logger.info("Using KinyaColBERT for Kinyarwanda-specific embeddings")
            self.embeddings = KinyaColBERTEmbeddings(
                model_name=getattr(settings, 'KINYACOLBERT_MODEL', 'anzeyimana/KinyaColBERT'),
                device='cpu'
            )
        else:
            logger.info(f"Initializing local embedding model: {settings.LOCAL_EMBEDDING_MODEL}")
            self.embeddings = HuggingFaceEmbeddings(
                model_name=settings.LOCAL_EMBEDDING_MODEL,
                model_kwargs={'device': 'cpu'},
                encode_kwargs={'normalize_embeddings': True}
            )
        
        # Local LLM via Ollama - Optimized for accuracy
        logger.info(f"Initializing local LLM (Ollama): {settings.OLLAMA_MODEL}")
        self.llm = Ollama(
            model=settings.OLLAMA_MODEL,
            base_url=settings.OLLAMA_BASE_URL,
            temperature=0.3,
            num_predict=500,
            top_k=20,
            top_p=0.95,
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
                    "model": settings.OLLAMA_MODEL,
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
            # Preprocess query for better matching
            processed_query = self._preprocess_query(query)
            logger.info(f"Original query: {query}")
            logger.info(f"Processed query: {processed_query}")
            
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
            logger.info(f"Looking for collection: {collection_name}")
            try:
                collection = self.chroma_client.get_collection(collection_name)
                logger.info(f"Found collection {collection_name} with {collection.count()} documents")
            except Exception as e:
                logger.error(f"Collection {collection_name} not found: {e}")
                return {
                    "answer": "I don't have any documents to search through yet. Please upload some documents first.",
                    "sources": [],
                    "confidence": 0.0,
                    "metadata": {"mode": "fast", "error": "no_documents"}
                }
            
            # Use cached context or retrieve new
            if cached_context:
                logger.info("Using cached context")
                results = {'documents': [cached_context], 'metadatas': [[{'cached': True}] * len(cached_context)]}
            else:
                # Simple vector search (no expansion, no reranking)
                # E5 models need "query: " prefix for good retrieval
                e5_prefix = "query: " if "e5" in settings.LOCAL_EMBEDDING_MODEL.lower() else ""
                logger.info(f"Generating embedding for query: {processed_query[:50]}...")
                query_embedding = self.embeddings.embed_query(e5_prefix + processed_query)
                # Retrieve more chunks to ensure we get the right service
                n_results = min(settings.RERANK_TOP_K * 2, 10)
                logger.info(f"Querying collection with n_results={n_results}")
                results = collection.query(
                    query_embeddings=[query_embedding],
                    n_results=n_results
                )
                logger.info(f"Query returned {len(results['documents'][0]) if results['documents'] else 0} results")
                
                # Cache the results
                if cache_key and results['documents'] and len(results['documents'][0]) > 0:
                    import time
                    self.context_cache[cache_key] = {
                        'chunks': results['documents'][0],
                        'timestamp': time.time()
                    }
                    logger.info(f"Cached {len(results['documents'][0])} chunks")
            
            # Build context from top results
            context_parts = []
            sources = []
            
            if results['documents'] and len(results['documents'][0]) > 0:
                # Filter chunks to keep only the most relevant service
                filtered_docs = self._filter_relevant_chunks(
                    results['documents'][0],
                    results['metadatas'][0],
                    processed_query
                )
                
                for i, (doc, metadata) in enumerate(filtered_docs[:settings.RERANK_TOP_K]):
                    context_parts.append(f"[Source {i+1}]: {doc}")
                    sources.append({
                        "content": doc[:200] + "..." if len(doc) > 200 else doc,
                        "metadata": metadata
                    })
            
            context = "\n\n".join(context_parts)
            
            # Debug logging
            logger.info(f"Retrieved {len(sources)} chunks for query")
            logger.info(f"Context length: {len(context)} characters")
            if len(context) > 0:
                logger.info(f"Context preview: {context[:200]}...")
            
            # Optimized Prompt: Direct Answer Only
            # Detect which service is being asked about
            query_lower = query.lower()
            service_instruction = ""
            if 'nandikishe' in query_lower or 'kwandikisha' in query_lower:
                service_instruction = "Look ONLY at the 'Kwandikisha Ubutaka' section."
            elif 'kugabanya' in query_lower or 'gukabanya' in query_lower:
                service_instruction = "Look ONLY at the 'Kugabanya Ubutaka' section."
            elif 'kwimura' in query_lower or 'imura' in query_lower:
                service_instruction = "Look ONLY at the 'Kwimura Izina' section."
            elif 'gukosora' in query_lower or 'kosora' in query_lower:
                service_instruction = "Look ONLY at the 'Gukosora Imbibi' section."
            elif 'guhuza' in query_lower or 'huza' in query_lower:
                service_instruction = "Look ONLY at the 'Guhuza Ibice' section."
            elif 'visa' in query_lower or 'viza' in query_lower:
                service_instruction = "Look ONLY at the 'Visa' section."
            elif 'pasiporo' in query_lower or 'passport' in query_lower:
                service_instruction = "Look ONLY at the 'Pasiporo' or 'Passport' section."
            elif 'irangamuntu' in query_lower or 'indangamuntu' in query_lower or 'resident id' in query_lower:
                service_instruction = "Look ONLY at the 'Irangamuntu' or 'Resident ID' section."
            elif 'laissez-passer' in query_lower:
                service_instruction = "Look ONLY at the 'Laissez-Passer' section."
            else:
                service_instruction = "Find the relevant service section in the context."
            
            # Detect what type of information is being asked
            info_type = ""
            if any(word in query_lower for word in ['ni iki', 'what is', 'ni nde', 'ibisobanuro']):
                info_type = "Answer with the definition/description from 'Ibisobanuro:' - explain what it is"
            elif any(word in query_lower for word in ['igihe', 'kingana iki', 'gutegereza', 'how long', 'time', 'bitwara']):
                info_type = "Start with 'Bitwara' or 'It takes' then give the complete time/duration from 'Igihe cyo gutegereza:' including units (iminsi, amasaha, etc.)"
            elif any(word in query_lower for word in ['igiciro', 'amafaranga', 'price', 'cost', 'angahe']):
                info_type = "Give the complete price information from 'Igiciro:' - include ALL price options with their details"
            elif any(word in query_lower for word in ['ibikenewe', 'gikenewe', 'requirements', 'required', 'inyandiko', 'ziki']):
                info_type = "Start with 'Ukeneye:' or 'You need:' then list ALL requirements from 'Ibikenewe:' - do NOT include time or price"
            elif any(word in query_lower for word in ['gute', 'how can', 'how do', 'nshobora', 'process', 'steps']):
                info_type = "Start with 'Kugira ngo ubone [service], ukeneye:' then list ALL requirements from 'Ibikenewe:' ONLY - do NOT include time or price"
            else:
                info_type = "Answer the specific question asked."
            
            prompt = f"""You are IremboChat. Answer based ONLY on the specific service asked about.

Context:
{context}

Question: {query}

STRICT RULES:
1. {service_instruction}
2. {info_type}
3. CRITICAL: If you see information from multiple services in the context, use ONLY the one mentioned in rule 1
4. DO NOT combine or mix requirements from different services
5. Answer in Kinyarwanda
6. List all items with bullet points (-)
7. Include the complete information from the document

Answer with ONLY information from the correct service:"""
            
            # Generate answer (Allow more tokens for complete answers)
            self.llm.num_predict = 600
            answer = self.llm.invoke(prompt)
            
            # Post-process: Remove description sections if present
            answer = self._clean_answer(answer, query)
            
            return {
                "answer": answer,
                "sources": sources,
                "confidence": 0.85,
                "metadata": {
                    "chunks_retrieved": len(sources),
                    "chunks_used": len(sources),
                    "model": settings.OLLAMA_MODEL,
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
            e5_prefix = "query: " if "e5" in settings.LOCAL_EMBEDDING_MODEL.lower() else ""
            query_embedding = self.embeddings.embed_query(e5_prefix + query)
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
    
    def _clean_answer(self, answer: str, query: str) -> str:
        """Clean answer to remove unwanted sections like descriptions"""
        import re
        
        # If query is about requirements (Ibikenewe/Requirements)
        if any(word in query.lower() for word in ['ibikenewe', 'gikenewe', 'requirements', 'required', 'need']):
            # Remove description/ibisobanuro sections
            # Pattern: Remove lines starting with "Description:" or "Ibisobanuro:"
            answer = re.sub(r'^(Description|Ibisobanuro):.*?(?=\n[A-Z]|\n-|\n\*|\Z)', '', answer, flags=re.MULTILINE | re.DOTALL)
            
            # If answer starts with a service name followed by description, remove it
            answer = re.sub(r'^.*?(Land Subdivision|Kugabanya Ubutaka).*?\n', '', answer, flags=re.MULTILINE)
            
            # Extract only the requirements section if present
            requirements_match = re.search(r'(Requirements|Ibikenewe):?\s*(.*?)(?=\n\n|\Z)', answer, re.DOTALL | re.IGNORECASE)
            if requirements_match:
                answer = requirements_match.group(2).strip()
        
        # If query is about price (Igiciro/Price)
        elif any(word in query.lower() for word in ['igiciro', 'price', 'cost', 'amafaranga']):
            price_match = re.search(r'(Price|Igiciro):?\s*(.*?)(?=\n\n|\Z)', answer, re.DOTALL | re.IGNORECASE)
            if price_match:
                answer = price_match.group(2).strip()
        
        # If query is about time (Igihe/Time)
        elif any(word in query.lower() for word in ['igihe', 'time', 'gutegereza', 'long']):
            time_match = re.search(r'(Time|Igihe):?\s*(.*?)(?=\n\n|\Z)', answer, re.DOTALL | re.IGNORECASE)
            if time_match:
                answer = time_match.group(2).strip()
        
        return answer.strip()
    
    def _preprocess_query(self, query: str) -> str:
        """Preprocess query to improve retrieval accuracy"""
        # Add key terms to help with matching
        query_lower = query.lower()
        
        # Map common verbs to service names - LAND SERVICES
        if 'nandikishe' in query_lower or 'kwandikisha' in query_lower:
            return query + " Kwandikisha Ubutaka"
        elif 'kugabanya' in query_lower or 'gukabanya' in query_lower:
            return query + " Kugabanya Ubutaka"
        elif 'kwimura' in query_lower or 'imura' in query_lower:
            return query + " Kwimura Izina"
        elif 'gukosora' in query_lower or 'kosora' in query_lower:
            return query + " Gukosora Imbibi"
        elif 'guhuza' in query_lower or 'huza' in query_lower:
            return query + " Guhuza Ibice"
        
        # IMMIGRATION SERVICES
        elif 'visa' in query_lower or 'viza' in query_lower:
            return query + " Visa"
        elif 'pasiporo' in query_lower or 'passport' in query_lower:
            return query + " Pasiporo"
        elif 'irangamuntu' in query_lower or 'indangamuntu' in query_lower or 'resident id' in query_lower:
            return query + " Irangamuntu"
        elif 'laissez-passer' in query_lower:
            return query + " Laissez-Passer"
        
        return query
    
    def _filter_relevant_chunks(self, documents: List[str], metadatas: List[Dict], query: str) -> List[tuple]:
        """Filter chunks to keep only those from the most relevant service"""
        query_lower = query.lower()
        
        # Define exact service names to match
        service_patterns = {
            # Land services
            'kwandikisha': ['kwandikisha ubutaka', 'land registration'],
            'kugabanya': ['kugabanya ubutaka', 'land subdivision'],
            'kwimura': ['kwimura izina', 'title transfer'],
            'gukosora': ['gukosora imbibi', 'boundary correction'],
            'guhuza': ['guhuza ibice', 'land consolidation'],
            # Immigration services
            'visa': ['gusaba viza', 'visa application'],
            'pasiporo': ['gusaba pasiporo', 'passport application', 'pasiporo y\'u rwanda'],
            'irangamuntu': ['irangamuntu ry\'abanyamahanga', 'foreigner id', 'resident id'],
            'laissez': ['laissez-passer'],
        }
        
        # Determine which service is being asked about
        target_patterns = []
        for key, patterns in service_patterns.items():
            if key in query_lower:
                target_patterns = patterns
                break
        
        if not target_patterns:
            # No specific service detected, return all chunks
            return [(doc, metadata) for doc, metadata in zip(documents, metadatas)]
        
        # Score each chunk - STRICT matching
        scored_chunks = []
        for doc, metadata in zip(documents, metadatas):
            doc_lower = doc.lower()
            score = 0
            
            # Check if this chunk contains the target service
            for pattern in target_patterns:
                if pattern in doc_lower:
                    score += 100  # Very high score for exact match
                    break
            
            # Penalize chunks that contain OTHER services
            for key, patterns in service_patterns.items():
                if key not in query_lower:  # This is a different service
                    for pattern in patterns:
                        if pattern in doc_lower and score < 100:
                            score -= 50  # Heavy penalty for wrong service
            
            scored_chunks.append((score, doc, metadata))
        
        # Sort by score and keep only positive scores
        scored_chunks.sort(key=lambda x: x[0], reverse=True)
        
        # Filter: only keep chunks with positive scores
        filtered = [(doc, metadata) for score, doc, metadata in scored_chunks if score > 0]
        
        # If no positive scores, return top 2 chunks anyway
        if not filtered:
            return [(doc, metadata) for score, doc, metadata in scored_chunks[:2]]
        
        return filtered
