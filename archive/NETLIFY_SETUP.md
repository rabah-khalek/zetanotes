# Netlify Feedback Form - Quick Setup

## Repository Info

ZetaNotes uses two repositories:
- **Deploy from:** `zetanotes-dev` (private repo with docs)
- **Issues go to:** `rabah-khalek/zetanotes` (private repo for issues)

Both repos are private, but users can submit feedback via the web form!

## What We've Set Up

✅ Netlify serverless function (`netlify/functions/submit-issue.js`)
✅ Netlify configuration (`netlify.toml`)
✅ Updated feedback form to use the function
✅ Package.json for dependencies
✅ Deployment guide

## Quick Start (3 Steps)

### 1. Create GitHub Token

Go to: https://github.com/settings/tokens
- Create new token (classic)
- Scope: **`repo`** (full control of private repositories)
- Copy the token

### 2. Deploy to Netlify

**Easy way (UI):**
1. Visit https://app.netlify.com
2. "Add new site" → "Import an existing project"
3. Connect GitHub → Select `zetanotes-dev` repo (private)
4. Publish directory: `docs`
5. Functions directory: `netlify/functions`
6. Deploy!

**Or via CLI:**
```bash
npm install -g netlify-cli
netlify login
netlify init
netlify deploy --prod
```

### 3. Add Token to Netlify

In Netlify dashboard:
1. Site settings → Environment variables
2. Add variable:
   - Key: `GITHUB_TOKEN`
   - Value: [your token from step 1]
3. Save

## Test It

Visit: `https://YOUR-SITE.netlify.app/feedback.html`

Fill out the form and submit. Check if an issue appears on GitHub!

## Update Your App

Once deployed, update the URL in `StatusFooterView.swift`:

```swift
// Replace:
if let url = URL(string: "https://rabah-khalek.github.io/zetanotes/feedback.html") {

// With your Netlify URL:
if let url = URL(string: "https://zetanotes.netlify.app/feedback.html") {
```

## How It Works

```
User fills form → feedback.html → Netlify Function → GitHub API → Issue created
                  (browser)      (serverless)     (secure token)
```

The GitHub token stays secure on Netlify's servers and is never exposed to users.

## Need Help?

See detailed guide: `docs/NETLIFY_DEPLOYMENT.md`
