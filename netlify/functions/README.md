# Netlify Functions

This directory contains serverless functions for ZetaNotes.

## Functions

### `submit-issue.js`

Handles feedback form submissions and creates GitHub issues.

**Endpoint:** `/.netlify/functions/submit-issue`

**Method:** POST

**Request Body:**
```json
{
  "title": "Issue title",
  "body": "Issue description",
  "labels": ["bug", "user-submitted"]
}
```

**Response:**
```json
{
  "success": true,
  "issue_url": "https://github.com/rabah-khalek/zetanotes/issues/123",
  "issue_number": 123
}
```

**Environment Variables Required:**
- `GITHUB_TOKEN` - GitHub Personal Access Token with `public_repo` scope

## Local Development

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Set up environment variable locally
echo "GITHUB_TOKEN=your_token_here" > .env

# Start dev server
netlify dev

# Function will be available at:
# http://localhost:8888/.netlify/functions/submit-issue
```

## Testing

```bash
# Test the function
curl -X POST http://localhost:8888/.netlify/functions/submit-issue \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Issue",
    "body": "This is a test",
    "labels": ["test"]
  }'
```

## Security

- GitHub token is stored securely in Netlify environment variables
- Token is never exposed to client-side code
- Function validates input before submission
- Consider adding rate limiting for production use
