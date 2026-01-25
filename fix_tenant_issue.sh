#!/bin/bash

cd backend
source venv/bin/activate

export PYTHONPATH="${PYTHONPATH}:$(pwd)"

python3 << 'EOF'
import os
os.chdir('/Users/kudzayi/RAG_2.0/backend')

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Connect to database
DATABASE_URL = "postgresql://kudzayi@localhost:5432/enterprise_rag"
engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)
session = Session()

# Check current users
print("\n=== Current Users ===")
result = session.execute(text("SELECT id, username, email, tenant_id FROM users ORDER BY id"))
for row in result:
    print(f"ID: {row[0]}, Username: {row[1]}, Email: {row[2]}, Tenant: {row[3]}")

# Update all users to tenant_id = 1 (where documents exist)
print("\n=== Updating all users to tenant_id = 1 ===")
session.execute(text("UPDATE users SET tenant_id = 1 WHERE tenant_id IS NULL OR tenant_id != 1"))
session.commit()

# Verify update
print("\n=== Updated Users ===")
result = session.execute(text("SELECT id, username, email, tenant_id FROM users ORDER BY id"))
for row in result:
    print(f"ID: {row[0]}, Username: {row[1]}, Email: {row[2]}, Tenant: {row[3]}")

session.close()
print("\n✅ All users now have tenant_id = 1 (matching the ChromaDB collection)")
EOF
