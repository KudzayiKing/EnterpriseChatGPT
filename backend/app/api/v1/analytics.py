from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from pydantic import BaseModel
from typing import List, Dict, Any
from datetime import datetime, timedelta

from app.db.database import get_db
from app.db.models import User, Analytics, Message, Document
from app.api.v1.auth import get_current_user

router = APIRouter()

class AnalyticsResponse(BaseModel):
    total_queries: int
    total_documents: int
    avg_response_time: float
    total_tokens_used: int
    total_cost: float

class UsageStats(BaseModel):
    date: str
    queries: int
    tokens: int

@router.get("/overview", response_model=AnalyticsResponse)
async def get_analytics_overview(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get analytics overview for current user"""
    
    # Total queries
    total_queries = db.query(func.count(Message.id)).filter(
        Message.conversation_id.in_(
            db.query(Message.conversation_id).join(Message.conversation).filter(
                Message.conversation.has(user_id=current_user.id)
            )
        ),
        Message.role == "user"
    ).scalar() or 0
    
    # Total documents
    total_documents = db.query(func.count(Document.id)).filter(
        Document.user_id == current_user.id
    ).scalar() or 0
    
    # Analytics data
    analytics_data = db.query(
        func.avg(Analytics.response_time).label("avg_response_time"),
        func.sum(Analytics.tokens_used).label("total_tokens"),
        func.sum(Analytics.cost).label("total_cost")
    ).filter(
        Analytics.user_id == current_user.id
    ).first()
    
    return {
        "total_queries": total_queries,
        "total_documents": total_documents,
        "avg_response_time": analytics_data.avg_response_time or 0.0,
        "total_tokens_used": analytics_data.total_tokens or 0,
        "total_cost": analytics_data.total_cost or 0.0
    }

@router.get("/usage", response_model=List[UsageStats])
async def get_usage_stats(
    days: int = 7,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get usage statistics for the last N days"""
    
    start_date = datetime.utcnow() - timedelta(days=days)
    
    stats = db.query(
        func.date(Analytics.created_at).label("date"),
        func.count(Analytics.id).label("queries"),
        func.sum(Analytics.tokens_used).label("tokens")
    ).filter(
        Analytics.user_id == current_user.id,
        Analytics.created_at >= start_date
    ).group_by(
        func.date(Analytics.created_at)
    ).all()
    
    return [
        {
            "date": str(stat.date),
            "queries": stat.queries,
            "tokens": stat.tokens or 0
        }
        for stat in stats
    ]
