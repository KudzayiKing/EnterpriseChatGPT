#!/usr/bin/env python3
import sys
from dotenv import load_dotenv

load_dotenv('backend/.env')
sys.path.insert(0, 'backend')

from app.db.database import SessionLocal
from app.db.models import User
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

db = SessionLocal()

# Check if user exists
existing_user = db.query(User).filter(User.username == "test").first()
if existing_user:
    print("User 'test' already exists!")
    db.close()
    sys.exit(0)

# Create test user
user = User(
    email="test@example.com",
    username="test",
    hashed_password=pwd_context.hash("test123"),
    is_active=True,
    is_superuser=False
)

db.add(user)
db.commit()
db.refresh(user)

print(f"✓ User created successfully!")
print(f"  Username: test")
print(f"  Password: test123")
print(f"  Email: test@example.com")

db.close()
