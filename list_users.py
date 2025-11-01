#!/usr/bin/env python3
import sys
import os
from dotenv import load_dotenv

# Load environment variables from backend/.env
load_dotenv('backend/.env')

sys.path.insert(0, 'backend')

from app.db.database import SessionLocal
from app.db.models import User
from datetime import datetime

db = SessionLocal()

print("\n" + "="*80)
print("REGISTERED USERS")
print("="*80 + "\n")

users = db.query(User).order_by(User.created_at.desc()).all()

if not users:
    print("No users found in the database.\n")
else:
    print(f"Total Users: {len(users)}\n")
    print(f"{'ID':<5} {'Email':<30} {'Username':<20} {'Active':<8} {'Admin':<8} {'Created':<20}")
    print("-" * 100)
    
    for user in users:
        created = user.created_at.strftime('%Y-%m-%d %H:%M:%S') if user.created_at else 'N/A'
        print(f"{user.id:<5} {user.email:<30} {user.username:<20} {'Yes' if user.is_active else 'No':<8} {'Yes' if user.is_superuser else 'No':<8} {created:<20}")

print("\n")
db.close()
