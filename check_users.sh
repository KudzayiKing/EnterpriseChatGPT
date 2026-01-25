#!/bin/bash

cd backend
source venv/bin/activate

python3 << 'EOF'
import sys
sys.path.insert(0, '.')

from app.database import SessionLocal
from app.models.user import User

db = SessionLocal()
users = db.query(User).all()
print("\n=== Users in Database ===")
for u in users:
    print(f'User: {u.username}, ID: {u.id}, Tenant: {u.tenant_id}')
db.close()
EOF
