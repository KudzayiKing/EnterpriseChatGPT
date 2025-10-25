# Contributing to Enterprise RAG 2.0

Thank you for your interest in contributing to Enterprise RAG 2.0!

## Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Submit a pull request

## Code Style

### Python (Backend)

- Follow PEP 8
- Use type hints
- Write docstrings for functions
- Maximum line length: 100 characters

```python
def process_document(
    file_path: str,
    tenant_id: int
) -> Dict[str, Any]:
    """
    Process a document and store in vector database.
    
    Args:
        file_path: Path to the document file
        tenant_id: ID of the tenant
        
    Returns:
        Dictionary with processing results
    """
    pass
```

### TypeScript (Frontend)

- Use TypeScript strict mode
- Follow Airbnb style guide
- Use functional components
- Prefer hooks over classes

```typescript
interface Props {
  message: string;
  onSend: (text: string) => void;
}

export const ChatInput: React.FC<Props> = ({ message, onSend }) => {
  // Component implementation
};
```

## Testing

### Backend Tests

```bash
cd backend
pytest tests/
```

### Frontend Tests

```bash
cd frontend
npm test
```

## Pull Request Process

1. Update documentation
2. Add tests for new features
3. Ensure all tests pass
4. Update CHANGELOG.md
5. Request review from maintainers

## Commit Messages

Use conventional commits:

```
feat: add document batch upload
fix: resolve authentication bug
docs: update API documentation
test: add RAG pipeline tests
refactor: improve query expansion logic
```

## Areas for Contribution

- RAG pipeline improvements
- New document format support
- UI/UX enhancements
- Performance optimizations
- Documentation
- Tests
- Bug fixes

## Questions?

Open an issue or contact the maintainers.
