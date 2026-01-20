#!/bin/bash

# Test authentication flow
echo "Testing authentication..."

# Get token from localStorage (you'll need to provide this)
echo ""
echo "To debug your issue, please run this in your browser console:"
echo ""
echo "console.log('Token:', localStorage.getItem('token'));"
echo ""
echo "Then test the token with:"
echo ""
echo "TOKEN='your-token-here'"
echo "curl -X GET http://localhost:8000/api/v1/auth/me \\"
echo "  -H 'Authorization: Bearer \$TOKEN'"
echo ""
echo "This will show if your token is valid or expired."
