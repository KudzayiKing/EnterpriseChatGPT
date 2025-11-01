#!/usr/bin/env python3
import sys
import os
from dotenv import load_dotenv

# Load environment variables from backend/.env
load_dotenv('backend/.env')

sys.path.insert(0, 'backend')

from app.db.database import SessionLocal
from app.db.models import User
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

db = SessionLocal()

print("\n" + "="*80)
print("PASSWORD RESET")
print("="*80 + "\n")

username = input("Enter username to reset password: ")
new_password = input("Enter new password: ")

user = db.query(User).filter(User.username == username).first()

if not user:
    print(f"\n❌ User '{username}' not found!\n")
else:
    user.hashed_password = pwd_context.hash(new_password)
    db.commit()
    print(f"\n✅ Password updated successfully for user '{username}'!\n")

db.close()
