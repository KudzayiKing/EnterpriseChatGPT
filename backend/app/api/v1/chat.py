from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

from app.db.database import get_db
from app.db.models import User, Conversation, Message
from app.api.v1.auth import get_current_user
from app.core.config import settings

# Use local or cloud RAG based on configuration
if getattr(settings, 'USE_LOCAL_MODELS', False):
    from app.core.rag_orchestrator_local import RAG2OrchestratorLocal as RAG2Orchestrator
else:
    from app.core.rag_orchestrator import RAG2Orchestrator

router = APIRouter()
rag_orchestrator = RAG2Orchestrator()

class MessageCreate(BaseModel):
    content: str
    conversation_id: Optional[int] = None
    rag_mode: Optional[str] = "fast"  # "fast" or "accurate"

class MessageResponse(BaseModel):
    id: int
    role: str
    content: str
    sources: List[Dict[str, Any]] = []
    created_at: datetime
    
    class Config:
        from_attributes = True

class ConversationResponse(BaseModel):
    id: int
    title: str
    created_at: datetime
    updated_at: datetime
    messages: List[MessageResponse] = []
    
    class Config:
        from_attributes = True

class ChatResponse(BaseModel):
    message: MessageResponse
    conversation_id: int

@router.post("/message", response_model=ChatResponse)
async def send_message(
    message: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message and get AI response"""
    
    # Get or create conversation
    if message.conversation_id:
        conversation = db.query(Conversation).filter(
            Conversation.id == message.conversation_id,
            Conversation.user_id == current_user.id
        ).first()
        if not conversation:
            raise HTTPException(status_code=404, detail="Conversation not found")
    else:
        conversation = Conversation(
            user_id=current_user.id,
            title=message.content[:50] + "..." if len(message.content) > 50 else message.content
        )
        db.add(conversation)
        db.commit()
        db.refresh(conversation)
    
    # Save user message
    user_message = Message(
        conversation_id=conversation.id,
        role="user",
        content=message.content
    )
    db.add(user_message)
    db.commit()
    
    # Get conversation history
    history = db.query(Message).filter(
        Message.conversation_id == conversation.id
    ).order_by(Message.created_at).all()
    
    conversation_history = [
        {"role": msg.role, "content": msg.content}
        for msg in history[:-1]  # Exclude current message
    ]
    
    # Process with RAG
    try:
        # Temporarily override RAG mode if specified
        original_mode = settings.RAG_MODE
        if message.rag_mode:
            settings.RAG_MODE = message.rag_mode
        
        rag_response = await rag_orchestrator.process_query(
            query=message.content,
            tenant_id=current_user.tenant_id or 0,
            conversation_history=conversation_history,
            conversation_id=conversation.id
        )
        
        # Restore original mode
        settings.RAG_MODE = original_mode
        
        # Save assistant message
        assistant_message = Message(
            conversation_id=conversation.id,
            role="assistant",
            content=rag_response["answer"],
            sources=rag_response["sources"],
            message_metadata=rag_response["metadata"]
        )
        db.add(assistant_message)
        db.commit()
        db.refresh(assistant_message)
        
        return {
            "message": assistant_message,
            "conversation_id": conversation.id
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing message: {str(e)}")

@router.get("/conversations", response_model=List[ConversationResponse])
async def get_conversations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all conversations for current user"""
    conversations = db.query(Conversation).filter(
        Conversation.user_id == current_user.id
    ).order_by(Conversation.updated_at.desc()).all()
    
    return conversations

@router.get("/conversations/{conversation_id}", response_model=ConversationResponse)
async def get_conversation(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific conversation with messages"""
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id
    ).first()
    
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    return conversation

@router.delete("/conversations/{conversation_id}")
async def delete_conversation(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a conversation"""
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id,
        Conversation.user_id == current_user.id
    ).first()
    
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    db.delete(conversation)
    db.commit()
    
    return {"message": "Conversation deleted successfully"}
