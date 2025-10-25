from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/enterprise_rag"
    REDIS_URL: str = "redis://localhost:6379"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # OpenAI (optional - only if not using local models)
    OPENAI_API_KEY: str = "not-needed"
    USE_LOCAL_MODELS: bool = True
    
    # Ollama configuration (for local models)
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama3.1:8b"
    LOCAL_EMBEDDING_MODEL: str = "sentence-transformers/all-MiniLM-L6-v2"
    
    # Application
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    CORS_ORIGINS: str = "http://localhost:3000"
    
    # File Upload
    MAX_UPLOAD_SIZE: int = 52428800  # 50MB
    UPLOAD_DIR: str = "./uploads"
    
    # Vector DB
    CHROMA_PERSIST_DIR: str = "./chroma_db"
    EMBEDDING_MODEL: str = "sentence-transformers/all-MiniLM-L6-v2"
    
    # RAG Configuration
    CHUNK_SIZE: int = 512
    CHUNK_OVERLAP: int = 50
    TOP_K_RETRIEVAL: int = 10
    RERANK_TOP_K: int = 5
    
    # Performance Mode: "fast" or "accurate"
    # fast: Skip query expansion, reranking, verification (5-15 seconds)
    # accurate: Full RAG 2.0 pipeline (60-90 seconds)
    RAG_MODE: str = "fast"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
