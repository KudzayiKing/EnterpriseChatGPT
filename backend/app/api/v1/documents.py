from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List
from datetime import datetime
import os
import shutil
from pathlib import Path

from app.db.database import get_db
from app.db.models import User, Document
from app.api.v1.auth import get_current_user
from app.core.document_processor import DocumentProcessor
from app.core.config import settings

router = APIRouter()
document_processor = DocumentProcessor()

class DocumentResponse(BaseModel):
    id: int
    filename: str
    file_type: str
    file_size: int
    status: str
    chunk_count: int
    created_at: datetime
    
    class Config:
        from_attributes = True

@router.post("/upload", response_model=DocumentResponse)
async def upload_document(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload and process a document"""
    
    # Validate file size
    file.file.seek(0, 2)
    file_size = file.file.tell()
    file.file.seek(0)
    
    if file_size > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=400, detail="File too large")
    
    # Get file extension
    file_ext = Path(file.filename).suffix.lower().replace(".", "")
    allowed_extensions = ["pdf", "docx", "doc", "pptx", "ppt", "xlsx", "xls", "html", "txt"]
    
    if file_ext not in allowed_extensions:
        raise HTTPException(status_code=400, detail=f"File type not supported. Allowed: {', '.join(allowed_extensions)}")
    
    # Create upload directory
    upload_dir = Path(settings.UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Save file
    file_path = upload_dir / f"{current_user.id}_{datetime.utcnow().timestamp()}_{file.filename}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Create document record
    document = Document(
        user_id=current_user.id,
        tenant_id=current_user.tenant_id or 0,
        filename=file.filename,
        file_path=str(file_path),
        file_type=file_ext,
        file_size=file_size,
        status="processing"
    )
    db.add(document)
    db.commit()
    db.refresh(document)
    
    # Process document asynchronously
    try:
        result = await document_processor.process_document(
            file_path=str(file_path),
            file_type=file_ext,
            tenant_id=current_user.tenant_id or 0,
            document_id=document.id,
            metadata={
                "filename": file.filename,
                "user_id": current_user.id
            }
        )
        
        # Update document status
        document.status = "completed" if result["status"] == "success" else result["status"]
        document.chunk_count = result.get("chunk_count", 0)
        db.commit()
        db.refresh(document)
        
    except Exception as e:
        document.status = "failed"
        db.commit()
        raise HTTPException(status_code=500, detail=f"Error processing document: {str(e)}")
    
    return document

@router.get("/", response_model=List[DocumentResponse])
async def get_documents(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all documents for current user"""
    documents = db.query(Document).filter(
        Document.user_id == current_user.id
    ).order_by(Document.created_at.desc()).all()
    
    return documents

@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific document"""
    document = db.query(Document).filter(
        Document.id == document_id,
        Document.user_id == current_user.id
    ).first()
    
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    
    return document

@router.delete("/{document_id}")
async def delete_document(
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a document"""
    document = db.query(Document).filter(
        Document.id == document_id,
        Document.user_id == current_user.id
    ).first()
    
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    
    # Delete file
    try:
        if os.path.exists(document.file_path):
            os.remove(document.file_path)
    except Exception as e:
        print(f"Error deleting file: {e}")
    
    # Delete from vector database
    try:
        await document_processor.delete_document_chunks(
            tenant_id=current_user.tenant_id or 0,
            document_id=document.id
        )
    except Exception as e:
        print(f"Error deleting chunks: {e}")
    
    # Delete from database
    db.delete(document)
    db.commit()
    
    return {"message": "Document deleted successfully"}
