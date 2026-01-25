#!/usr/bin/env python3
"""Fix tenant_id for user to match documents in ChromaDB"""

import sys
import os

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

from app.database import SessionLocal
from app.models.user import User

def fix_tenant():
    db = SessionLocal()
    try:
        # Get all users
        users = db.query(User).all()
        
        print("\n=== Current Users ===")
        for u in users:
            print(f"User: {u.username}, ID: {u.id}, Tenant: {u.tenant_id}")
        
        # Update all users to tenant_id = 1 (where documents are)
        print("\n=== Updating all users to tenant_id = 1 ===")
        for u in users:
            u.tenant_id = 1
            print(f"Updated {u.username} to tenant_id = 1")
        
        db.commit()
        print("\n✅ All users updated successfully!")
        
        print("\n=== Updated Users ===")
        users = db.query(User).all()
        for u in users:
            print(f"User: {u.username}, ID: {u.id}, Tenant: {u.tenant_id}")
            
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    fix_tenant()
