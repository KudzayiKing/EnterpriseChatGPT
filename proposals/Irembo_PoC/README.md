# Irembo Services AI Assistant - Proof of Concept
**(Land and Immigration Focus)**

## Overview
This Proof of Concept (PoC) demonstrates how the **Enterprise RAG 2.0** platform can be deployed to enhance the **IremboGov** user experience. By ingesting service documentation into a secure, Retrieval-Augmented Generation (RAG) system, we create an AI assistant capable of guiding citizens through complex procedures with accurate, official information.

## Scope
For this PoC, we focus on two critical sectors:
1.  **Land Services**: Registration, Transfers, Subdivision, etc.
2.  **Immigration Services**: Visas, Passports, Resident IDs, etc.

## Architecture
- **Engine**: Enterprise RAG 2.0 (Local/Private Deployment)
- **Knowledge Base**: Curated data derived from Irembo service descriptions.
- **Privacy**: All data processing happens within the secure infrastructure (no external API calls for sensitive data).

## Deployment Instructions

### 1. Prerequisites
Ensure the RAG backend is running:
```bash
./start-local.sh
# OR
cd backend && make run-backend
```

### 2. Run the PoC Setup
We have provided a script to automatically ingest the Land and Immigration data and run test queries.
```bash
chmod +x proposals/Irembo_PoC/setup_poc.sh
./proposals/Irembo_PoC/setup_poc.sh
```

### 3. Interactive Testing
Once the setup is complete, you can interact with the assistant via the Web UI (frontend) or use the API manually.

**Sample Questions:**
- "How much does it cost to transfer land I bought?"
- "I need to renew my passport, what documents do I need?"
- "Explain the process of land subdivision."
- "Can I get a visa on arrival?"

## Data Sources
The mock data for this PoC is located in `proposals/Irembo_PoC/data/`.
- `land_services.txt`: Contains details on land registration, transfer, subdivision, etc.
- `immigration_services.txt`: Contains details on visas, passports, and residency.

## Next Steps for Production
1.  **Full Ingestion**: Crawl and ingest the full IremboGov support portal.
2.  **Integration**: Embed the chat widget into the IremboGov portal.
3.  **Multilingual Support**: Enable Kinyarwanda, French, and English support (RAG 2.0 supports this natively).
