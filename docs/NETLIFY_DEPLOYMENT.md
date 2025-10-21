# Netlify Deployment Guide for ZetaNotes Feedback Form

## Repository Setup

**Important:** ZetaNotes uses two repositories:
- **`zetanotes-dev`** (private) - Contains the source code and docs folder
- **`rabah-khalek/zetanotes`** (private) - Repository for issues and releases

You'll deploy Netlify from the **private** `zetanotes-dev` repo, but feedback form submissions will create issues on the **private** `rabah-khalek/zetanotes` repo. This keeps both your development code and issue tracking private while still allowing users to submit feedback through the web form.

## Prerequisites

1. A Netlify account (free tier is sufficient)
2. A GitHub Personal Access Token with `repo` scope (for private repo access)

## Step 1: Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Name it: `ZetaNotes Feedback Form`
4. Set expiration: 1 year (or no expiration)
5. Select scope: **`repo`** (Full control of private repositories)
   - ⚠️ Note: If your `rabah-khalek/zetanotes` repo is **public**, you only need `public_repo` scope
   - ✅ Since your repo is **private**, you need the full `repo` scope to create issues
6. Click "Generate token"
7. **Copy the token immediately** (you won't see it again)

**Note:** The `repo` scope gives full access to your private repositories. Keep this token secure! It's only used server-side in Netlify's environment variables and never exposed to users.

## Step 2: Deploy to Netlify

### Option A: Deploy via Netlify UI (Easiest)

1. Go to https://app.netlify.com
2. Click "Add new site" → "Import an existing project"
3. Choose "GitHub" and authorize Netlify
4. Select your **`zetanotes-dev`** repository (the private repo with docs)
5. Configure build settings:
   - **Build command:** Leave empty
   - **Publish directory:** `docs`
   - **Functions directory:** `netlify/functions`
6. Click "Deploy site"

**Important Note:** Even though you're deploying from the private `zetanotes-dev` repo, the feedback form will create issues on the **public** `rabah-khalek/zetanotes` repo. This is configured in the Netlify function and keeps your development repo private while allowing public feedback.

### Option B: Deploy via Netlify CLI

```bash
# Install Netlify CLI globally
npm install -g netlify-cli

# Login to Netlify
netlify login

# Initialize Netlify in your project
cd /path/to/zetanotes-dev
netlify init

# Follow the prompts:
# - Create & configure a new site
# - Choose your team
# - Site name: zetanotes (or your preferred name)

# Deploy
netlify deploy --prod
```

## Step 3: Add Environment Variable

1. Go to your Netlify site dashboard
2. Navigate to **Site settings** → **Environment variables**
3. Click "Add a variable"
4. Add the following:
   - **Key:** `GITHUB_TOKEN`
   - **Value:** Paste your GitHub token from Step 1
   - **Scopes:** Check all (or at least "Functions")
5. Click "Create variable"

## Step 4: Update Your Domain

If you want to use a custom domain:

1. Go to **Site settings** → **Domain management**
2. Add your custom domain
3. Follow DNS configuration instructions

Or use the Netlify subdomain (e.g., `zetanotes.netlify.app`)

## Step 5: Update URLs in Your App

Update the feedback URL in `StatusFooterView.swift`:

```swift
// Change from GitHub Pages URL to your Netlify URL
if let url = URL(string: "https://YOUR-SITE-NAME.netlify.app/feedback.html") {
    NSWorkspace.shared.open(url)
}
```

Or if using custom domain:
```swift
if let url = URL(string: "https://zetanotes.com/feedback.html") {
    NSWorkspace.shared.open(url)
}
```

## Testing

1. Visit your deployed feedback form: `https://YOUR-SITE-NAME.netlify.app/feedback.html`
2. Fill out the form
3. Submit
4. Check if an issue appears on GitHub: https://github.com/rabah-khalek/zetanotes/issues

## Troubleshooting

### Function not working?

Check the function logs:
```bash
netlify functions:list
netlify functions:invoke submit-issue --payload '{"title":"Test","body":"Test body","labels":["test"]}'
```

Or in Netlify UI: **Functions** tab → Click on `submit-issue` → View logs

### Common Issues

1. **"Server configuration error"**
   - Environment variable `GITHUB_TOKEN` is not set
   - Go to Site settings → Environment variables and verify

2. **"401 Unauthorized"**
   - GitHub token is invalid or expired
   - Create a new token and update the environment variable

3. **"404 Not Found"**
   - Function path might be wrong
   - Verify it's deployed: check Functions tab in Netlify

4. **CORS errors**
   - Should not happen with Netlify functions, but if it does:
   - Add CORS headers in `submit-issue.js`

## Local Development

Test the function locally:

```bash
# Install dependencies
npm install

# Start Netlify dev server
netlify dev

# This will start:
# - Static site at http://localhost:8888
# - Functions at http://localhost:8888/.netlify/functions/submit-issue

# Test the form at http://localhost:8888/feedback.html
```

## Security Notes

✅ **Good:**
- GitHub token is stored securely in Netlify environment variables
- Token is never exposed in client-side code
- Function validates and sanitizes input

⚠️ **Be aware:**
- Anyone can submit issues through your form
- Consider adding rate limiting if abuse occurs
- You can add reCAPTCHA if needed

## Monitoring

Monitor your feedback submissions:
- Check GitHub issues: https://github.com/rabah-khalek/zetanotes/issues?q=label%3Auser-submitted
- View function logs in Netlify dashboard
- Set up email notifications in GitHub for new issues

## Next Steps

1. Test the form thoroughly
2. Monitor for spam/abuse
3. Consider adding reCAPTCHA if needed
4. Set up GitHub issue templates for better organization
5. Add auto-labeling based on issue content (optional)
