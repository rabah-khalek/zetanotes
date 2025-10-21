# Feedback Form Setup

The feedback form (`feedback.html`) allows users to submit issues without a GitHub account. To make it work, you need to set up a GitHub Personal Access Token.

## Option 1: GitHub Personal Access Token (Simple but less secure)

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name like "ZetaNotes Feedback Form"
4. Set expiration (recommend: 1 year)
5. Select scope: `public_repo` only
6. Generate and copy the token
7. In `docs/feedback.html`, replace `YOUR_GITHUB_TOKEN_HERE` with your token

⚠️ **Warning**: This exposes your token in the HTML source. Anyone can see it and use it.

## Option 2: Serverless Function (Recommended - More Secure)

Use a serverless function to proxy the GitHub API call and keep your token secret.

### Using Netlify Functions:

1. Create `netlify/functions/submit-issue.js`:

```javascript
const fetch = require('node-fetch');

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  const { title, body, labels } = JSON.parse(event.body);

  try {
    const response = await fetch('https://api.github.com/repos/rabah-khalek/zetanotes/issues', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `token ${process.env.GITHUB_TOKEN}`,
        'Accept': 'application/vnd.github.v3+json'
      },
      body: JSON.stringify({ title, body, labels })
    });

    const data = await response.json();
    
    return {
      statusCode: response.status,
      body: JSON.stringify(data)
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
```

2. Create `netlify.toml`:

```toml
[build]
  functions = "netlify/functions"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

3. Add your GitHub token as an environment variable in Netlify:
   - Go to Site settings → Environment variables
   - Add `GITHUB_TOKEN` with your token value

4. Update `feedback.html` to use the function endpoint instead of GitHub API directly:

```javascript
// Replace GITHUB_API_URL with:
const API_URL = '/.netlify/functions/submit-issue';

// Remove GITHUB_TOKEN constant

// In the fetch call, change to:
const response = await fetch(API_URL, {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify(issueData)
});
```

### Using Vercel:

Similar setup but use `api/submit-issue.js` in the root directory.

## Option 3: GitHub App (Most Secure - For Production)

For production, consider creating a GitHub App with issue creation permissions. This is more complex but provides better security and rate limiting.

## Current Status

The feedback form is currently configured but needs a token/function setup to work. Users can still click "view existing issues" to go directly to GitHub.

## Testing

1. Deploy your changes
2. Visit `https://rabah-khalek.github.io/zetanotes/feedback.html`
3. Fill out the form
4. Submit and verify an issue is created on GitHub

## Alternative: Simple Email Collection

If GitHub API integration is too complex, you can also:
1. Use a service like Formspree, Google Forms, or Tally
2. Collect feedback via email
3. Manually create GitHub issues from submissions
