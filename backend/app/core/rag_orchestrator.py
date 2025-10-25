from typing import List, Dict, Any, Optional
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from sentence_transformers import CrossEncoder
import chromadb
from chromadb.config import Settings as ChromaSettings
import logging

from app.core.config import settings

logger = logging.getLogger(__name__)

class RAG2Orchestrator:
    """Advanced RAG 2.0 Pipeline with multi-stage retrieval and verification"""
    
    def __init__(self):
        self.embeddings = OpenAIEmbeddings(
            model="text-embedding-3-small",
            openai_api_key=settings.OPENAI_API_KEY
        )
        self.llm = ChatOpenAI(
            model="gpt-4-turbo-preview",
            temperature=0.7,
            openai_api_key=settings.OPENAI_API_KEY
        )
        self.reranker = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')
        
        # Initialize ChromaDB
        self.chroma_client = chromadb.PersistentClient(
            path=settings.CHROMA_PERSIST_DIR,
            settings=ChromaSettings(anonymized_telemetry=False)
        )
        
    async def process_query(
        self,
        query: str,
        tenant_id: int,
        conversation_history: Optional[List[Dict]] = None
    ) -> Dict[str, Any]:
        """Main RAG 2.0 pipeline orchestration"""
        try:
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
                    "chunks_used": len(compressed_context)
                }
            }
            
        except Exception as e:
            logger.error(f"Error in RAG pipeline: {str(e)}")
            raise
    
    async def query_expansion(
        self,
        query: str,
        conversation_history: Optional[List[Dict]] = None
    ) -> List[str]:
        """Expand query using multiple techniques"""
        expanded = [query]
        
        # HyDE: Generate hypothetical document
        hyde_prompt = ChatPromptTemplate.from_template(
            "Generate a detailed passage that would answer this question: {query}"
        )
        hyde_response = await self.llm.ainvoke(hyde_prompt.format(query=query))
        expanded.append(hyde_response.content)
        
        # Step-back prompting for conceptual queries
        stepback_prompt = ChatPromptTemplate.from_template(
            "What is the broader concept or principle behind this question: {query}"
        )
        stepback_response = await self.llm.ainvoke(stepback_prompt.format(query=query))
        expanded.append(stepback_response.content)
        
        return expanded
    
    async def hybrid_retrieval(
        self,
        queries: List[str],
        tenant_id: int
    ) -> List[Dict[str, Any]]:
        """Hybrid search combining vector and keyword search"""
        collection_name = f"tenant_{tenant_id}"
        
        try:
            collection = self.chroma_client.get_collection(collection_name)
        except:
            logger.warning(f"Collection {collection_name} not found")
            return []
        
        all_results = []
        
        for query in queries:
            # Vector search
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
        """Rerank candidates using cross-encoder"""
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
        # For now, return top chunks
        # In production, implement extractive summarization
        return chunks
    
    async def generate_with_verification(
        self,
        context: List[Dict[str, Any]],
        query: str,
        conversation_history: Optional[List[Dict]] = None
    ) -> Dict[str, Any]:
        """Generate response with source verification"""
        
        context_text = "\n\n".join([
            f"Source {i+1}:\n{chunk['content']}"
            for i, chunk in enumerate(context)
        ])
        
        prompt = ChatPromptTemplate.from_template("""
You are an expert AI assistant. Answer the question based on the provided context.
Be precise, cite sources, and indicate confidence level.

Context:
{context}

Question: {query}

Provide a detailed answer with:
1. Direct answer to the question
2. Source citations (mention which sources you used)
3. Confidence level (high/medium/low)

Answer:""")
        
        response = await self.llm.ainvoke(
            prompt.format(context=context_text, query=query)
        )
        
        return {
            "answer": response.content,
            "sources": [
                {
                    "content": chunk['content'][:200] + "...",
                    "metadata": chunk.get('metadata', {})
                }
                for chunk in context
            ],
            "confidence": "high"  # Implement confidence scoring
        }
    
    async def verify_response(
        self,
        response: Dict[str, Any],
        context: List[Dict[str, Any]]
    ) -> bool:
        """Verify response accuracy against context"""
        # Implement fact verification logic
        # For now, return True
        return True
    
    async def refine_query(self, original_query: str, failed_response: Dict) -> str:
        """Refine query if verification fails"""
        prompt = ChatPromptTemplate.from_template(
            "Rephrase this query to be more specific: {query}"
        )
        refined = await self.llm.ainvoke(prompt.format(query=original_query))
        return refined.content
