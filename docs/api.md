# API Documentation

## Base URL

```
Development: http://localhost:8000
Production: https://api.yourdomain.com
```

## Authentication

All authenticated endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

## Endpoints

### Authentication

#### Register User

```http
POST /api/v1/auth/register
```

**Request Body**:
```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "password123",
  "full_name": "John Doe",
  "tenant_name": "Acme Corp"
}
```

**Response**:
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "username",
  "full_name": "John Doe",
  "is_active": true,
  "tenant_id": 1
}
```

#### Login

```http
POST /api/v1/auth/login
```

**Request Body** (form-urlencoded):
```
username=username&password=password123
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

#### Get Current User

```http
GET /api/v1/auth/me
```

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "username",
  "full_name": "John Doe",
  "is_active": true,
  "tenant_id": 1
}
```

### Chat

#### Send Message

```http
POST /api/v1/chat/message
```

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
  "content": "What is the minimum documents I can upload?",
  "conversation_id": 1,
  "rag_mode": "fast"
}
```

**Parameters**:
- `content` (required): The user's message
- `conversation_id` (optional): ID of existing conversation
- `rag_mode` (optional): "fast" or "accurate" (default: "fast")

**Response**:
```json
{
  "message": {
    "id": 2,
    "role": "assistant",
    "content": "Based on the documentation, you can upload a minimum of 1 document...",
    "sources": [
      {
        "content": "Document upload limits: minimum 1, maximum 1000...",
        "metadata": {
          "filename": "documentation.pdf",
          "chunk_index": 5,
          "document_id": 3
        }
      }
    ],
    "created_at": "2025-10-25T10:30:00Z"
  },
  "conversation_id": 1
}
```

**Response Metadata**:
```json
{
  "metadata": {
    "mode": "fast",
    "chunks_retrieved": 5,
    "chunks_used": 5,
    "model": "local-llama3.1-8b",
    "cached": false
  }
}
```

#### Get Conversations

```http
GET /api/v1/chat/conversations
```

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
[
  {
    "id": 1,
    "title": "Document Upload Questions",
    "created_at": "2025-10-25T10:00:00Z",
    "updated_at": "2025-10-25T10:30:00Z"
  }
]
```

#### Get Conversation

```http
GET /api/v1/chat/conversations/{conversation_id}
```

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "id": 1,
  "title": "Document Upload Questions",
  "created_at": "2025-10-25T10:00:00Z",
  "updated_at": "2025-10-25T10:30:00Z",
  "messages": [
    {
      "id": 1,
      "role": "user",
      "content": "What is the minimum documents I can upload?",
      "sources": [],
      "created_at": "2025-10-25T10:00:00Z"
    },
    {
      "id": 2,
      "role": "assistant",
      "content": "Based on the documentation...",
      "sources": [...],
      "created_at": "2025-10-25T10:00:05Z"
    }
  ]
}
```

#### Delete Conversation

```http
DELETE /api/v1/chat/conversations/{conversation_id}
```

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "message": "Conversation deleted successfully"
}
```

### Documents

#### Upload Document

```http
POST /api/v1/documents/upload
```

**Headers**: 
- `Authorization: Bearer <token>`
- `Content-Type: multipart/form-data`

**Request Body**:
```
file: <binary file data>
```

**Supported Formats**:
- PDF (.pdf)
- Word (.docx, .doc)
- PowerPoint (.pptx, .ppt)
- Excel (.xlsx, .xls)
- HTML (.html)
- Text (.txt)

**Max File Size**: 50MB

**Response**:
```json
{
  "id": 1,
  "filename": "documentation.pdf",
  "file_type": "pdf",
  "file_size": 2048000,
  "status": "completed",
  "chunk_count": 42,
  "created_at": "2025-10-25T10:00:00Z"
}
```

**Status Values**:
- `processing`: Document is being processed
- `completed`: Ready for querying
- `failed`: Processing error occurred

#### Get Documents

```http
GET /api/v1/documents/
```

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
[
  {
    "id": 1,
    "filename": "documentation.pdf",
    "file_type": "pdf",
    "file_size": 2048000,
    "status": "completed",
    "chunk_count": 42,
    "created_at": "2025-10-25T10:00:00Z"
  },
  {
    "id": 2,
    "filename": "guide.docx",
    "file_type": "docx",
    "file_size": 1024000,
    "status": "completed",
    "chunk_count": 28,
    "created_at": "2025-10-25T09:30:00Z"
  }
]
```

#### Get Document

```http
GET /api/v1/documents/{document_id}
```

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "id": 1,
  "filename": "documentation.pdf",
  "file_type": "pdf",
  "file_size": 2048000,
  "status": "completed",
  "chunk_count": 42,
  "created_at": "2025-10-25T10:00:00Z"
}
```

#### Delete Document

```http
DELETE /api/v1/documents/{document_id}
```

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "message": "Document deleted successfully"
}
```

**Note**: Deletes both the file and all associated vector embeddings.

### Analytics

#### Get Analytics Overview

```http
GET /api/v1/analytics/overview
```

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "total_queries": 150,
  "total_documents": 25,
  "avg_response_time": 8.5,
  "total_tokens_used": 0,
  "total_cost": 0.00
}
```

**Note**: `total_cost` is always $0 since we use local models.

#### Get Usage Statistics

```http
GET /api/v1/analytics/usage?days=7
```

**Headers**: `Authorization: Bearer <token>`

**Query Parameters**:
- `days` (optional): Number of days to retrieve (default: 7)

**Response**:
```json
[
  {
    "date": "2025-10-25",
    "queries": 25,
    "fast_mode": 20,
    "accurate_mode": 5,
    "avg_response_time": 7.2
  },
  {
    "date": "2025-10-24",
    "queries": 30,
    "fast_mode": 25,
    "accurate_mode": 5,
    "avg_response_time": 8.1
  }
]
```

## Error Responses

### 400 Bad Request

```json
{
  "detail": "Invalid request parameters"
}
```

**Common Causes**:
- Missing required fields
- Invalid file format
- File too large

### 401 Unauthorized

```json
{
  "detail": "Could not validate credentials"
}
```

**Common Causes**:
- Missing Authorization header
- Expired token
- Invalid token

### 404 Not Found

```json
{
  "detail": "Resource not found"
}
```

**Common Causes**:
- Invalid conversation_id
- Invalid document_id
- Deleted resource

### 500 Internal Server Error

```json
{
  "detail": "Error processing document: [error message]"
}
```

**Common Causes**:
- Document processing failure
- Database connection error
- Ollama service not running

## Rate Limiting

**Current Limits**:
- No rate limiting (local deployment)
- Can be configured for production

**Recommended Production Limits**:
- 100 requests per minute per user
- 1000 requests per hour per user

## Performance Notes

### Response Times

**Fast Mode**:
- First query: 5-10 seconds
- Follow-up (cached): 2-5 seconds

**Accurate Mode**:
- All queries: 60-90 seconds

### Concurrent Requests

**Recommended**:
- Max 5 concurrent chat requests
- Max 2 concurrent document uploads

**Reason**: Local models are CPU-intensive

## WebSocket Support

**Status**: Not yet implemented

**Planned**:
```javascript
ws://localhost:8000/ws/chat/{conversation_id}
```

**Features**:
- Real-time message streaming
- Token-by-token generation
- Live document processing updates

## API Versioning

**Current Version**: v1

**URL Pattern**: `/api/v1/...`

**Future Versions**: Will be added as `/api/v2/...` without breaking v1

## Testing

**Interactive API Docs**:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

**Example cURL**:
```bash
# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=testpass"

# Send message
curl -X POST http://localhost:8000/api/v1/chat/message \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "What is RAG?", "rag_mode": "fast"}'
```

## SDK Support

**Status**: Not yet available

**Planned**:
- Python SDK
- JavaScript/TypeScript SDK
- REST client examples
