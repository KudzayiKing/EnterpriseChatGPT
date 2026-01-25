"""
KinyaColBERT Embeddings for Kinyarwanda-specific semantic search
Based on: anzeyimana/KinyaColBERT from HuggingFace
"""
import logging
from typing import List
import torch
from transformers import AutoTokenizer, AutoModel
import numpy as np

logger = logging.getLogger(__name__)


class KinyaColBERTEmbeddings:
    """
    Custom embedding function using KinyaColBERT for superior Kinyarwanda semantic search.
    
    KinyaColBERT uses:
    - Late word-level interactions between queries and documents
    - Morphology-based tokenization
    - Two-tier transformer encoding
    """
    
    def __init__(self, model_name: str = "anzeyimana/KinyaColBERT", device: str = "cpu"):
        """
        Initialize KinyaColBERT embeddings
        
        Args:
            model_name: HuggingFace model identifier
            device: Device to run model on ('cpu' or 'cuda')
        """
        self.model_name = model_name
        self.device = device
        
        logger.info(f"Loading KinyaColBERT model: {model_name}")
        
        try:
            self.tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
            self.model = AutoModel.from_pretrained(model_name, trust_remote_code=True)
            self.model.to(device)
            self.model.eval()
            
            logger.info("KinyaColBERT model loaded successfully")
        except Exception as e:
            logger.error(f"Error loading KinyaColBERT: {str(e)}")
            logger.info("Falling back to KinyaBERT-large as alternative")
            # Fallback to KinyaBERT if KinyaColBERT not available
            self.tokenizer = AutoTokenizer.from_pretrained("jean-paul/KinyaBERT-large")
            self.model = AutoModel.from_pretrained("jean-paul/KinyaBERT-large")
            self.model.to(device)
            self.model.eval()
    
    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        """
        Embed a list of documents
        
        Args:
            texts: List of document texts to embed
            
        Returns:
            List of embedding vectors
        """
        embeddings = []
        
        # Process in batches to avoid memory issues
        batch_size = 8
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            batch_embeddings = self._encode_batch(batch)
            embeddings.extend(batch_embeddings)
        
        return embeddings
    
    def embed_query(self, text: str) -> List[float]:
        """
        Embed a single query
        
        Args:
            text: Query text to embed
            
        Returns:
            Embedding vector
        """
        return self._encode_batch([text])[0]
    
    def _encode_batch(self, texts: List[str]) -> List[List[float]]:
        """
        Encode a batch of texts into embeddings
        
        Args:
            texts: List of texts to encode
            
        Returns:
            List of embedding vectors
        """
        # Tokenize
        encoded = self.tokenizer(
            texts,
            padding=True,
            truncation=True,
            max_length=512,
            return_tensors="pt"
        )
        
        # Move to device
        encoded = {k: v.to(self.device) for k, v in encoded.items()}
        
        # Generate embeddings
        with torch.no_grad():
            outputs = self.model(**encoded)
            
            # Use mean pooling over token embeddings
            embeddings = self._mean_pooling(outputs, encoded['attention_mask'])
            
            # Normalize embeddings
            embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
        
        # Convert to list
        return embeddings.cpu().numpy().tolist()
    
    def _mean_pooling(self, model_output, attention_mask):
        """
        Mean pooling - take attention mask into account for correct averaging
        
        Args:
            model_output: Model output containing last_hidden_state
            attention_mask: Attention mask from tokenizer
            
        Returns:
            Pooled embeddings
        """
        token_embeddings = model_output.last_hidden_state
        input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        
        sum_embeddings = torch.sum(token_embeddings * input_mask_expanded, 1)
        sum_mask = torch.clamp(input_mask_expanded.sum(1), min=1e-9)
        
        return sum_embeddings / sum_mask
