#!/usr/bin/env python3
import sys
import os
from dotenv import load_dotenv

load_dotenv('backend/.env')
sys.path.insert(0, 'backend')

from app.db.database import SessionLocal
from app.db.models import User
from passlib.context import CryptContext

# Use the same context as auth.py
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

db = SessionLocal()

username = "King"
password = "test123"

user = db.query(User).filter(User.username == username).first()

if user:
    print(f"User found: {user.username}")
    print(f"Stored hash: {user.hashed_password[:50]}...")
    print(f"Testing password: {password}")
    
    is_valid = pwd_context.verify(password, user.hashed_password)
    print(f"Password valid: {is_valid}")
    
    if not is_valid:
        print("\nResetting password to 'test123'...")
        user.hashed_password = pwd_context.hash(password)
        db.commit()
        print("Password reset complete!")
        
        # Test again
        is_valid = pwd_context.verify(password, user.hashed_password)
        print(f"Password now valid: {is_valid}")
else:
    print(f"User '{username}' not found")

db.close()
