# CI/CD Workflows Documentation

This repository contains two GitHub Actions workflows for managing ZetaNotes distribution.

## Workflows Overview

### 1. Release Workflow (`release.yml`)

**Purpose**: Build app, create releases, and deploy to public repository

**Triggers**:

- Git tags matching `v*` (e.g., `v1.0.0`, `v1.2.1`)
- Manual dispatch with version input

**What it does**:

1. Builds ZetaNotes app using Xcode
2. Creates DMG installer
3. Generates Sparkle EdDSA signatures
4. Creates GitHub release in `rabah-khalek/zetanotes`
5. Updates appcast.xml with new release info
6. Copies all docs to public repo
7. Triggers GitHub Pages deployment

**Usage**:

```bash
# Automatic via git tag
git tag v1.0.0
git push origin v1.0.0

# Manual via GitHub Actions UI
# Go to Actions → Release → Run workflow → Enter version
```

### 2. Website Update Workflow (`update-website.yml`)

**Purpose**: Update GitHub Pages website without creating a release

**Triggers**:

- Changes to `docs/**` files on main branch
- Manual dispatch

**What it does**:

1. Copies website files to public repo
2. Preserves existing appcast.xml (doesn't overwrite releases)
3. Updates GitHub Pages content
4. Only commits if changes are detected

**Files synchronized**:

- `docs/index.html` → Main website
- `docs/download.html` → Download page
- `docs/logo.png` → App logo
- `docs/appcast.xml` → Only if doesn't exist (preserves releases)

## Workflow Comparison

| Feature | Release Workflow | Website Update |
|---------|------------------|----------------|
| **Builds App** | ✅ Yes | ❌ No |
| **Creates Release** | ✅ Yes | ❌ No |
| **Updates Website** | ✅ Yes | ✅ Yes |
| **Preserves Releases** | ❌ Overwrites appcast.xml | ✅ Preserves appcast.xml |
| **Trigger** | Git tags, manual | File changes, manual |
| **Use Case** | New app versions | Website content updates |

## Common Use Cases

### Scenario 1: Release New App Version

Use the **Release Workflow**:

```bash
git tag v1.1.0
git push origin v1.1.0
```

### Scenario 2: Update Website Content Only

Edit files in `docs/` and push to main:

```bash
# Edit docs/index.html, docs/download.html, etc.
git add docs/
git commit -m "Update website content"
git push origin main
# Website Update Workflow triggers automatically
```

### Scenario 3: Manual Website Update

Use GitHub Actions UI:

1. Go to **Actions** → **Update Website**
2. Click **Run workflow**
3. Optionally check "Force update website"

### Scenario 4: Fix Website After Release

If the release workflow updated the website incorrectly:

1. Fix the files in `docs/`
2. Push to main (triggers Website Update)
3. The Website Update preserves the appcast.xml from the release

## Required Secrets

Both workflows require these secrets in the **zetanotes-dev** repository:

### PUBLIC_REPO_TOKEN

- **Type**: GitHub Personal Access Token (Classic)
- **Scopes**: `repo`, `workflow`
- **Purpose**: Allow pushing to the public `zetanotes` repository

### SPARKLE_PRIVATE_KEY

- **Type**: EdDSA Private Key
- **Purpose**: Sign app updates for Sparkle framework
- **Usage**: Only used by Release Workflow

## GitHub Pages Setup

1. **Enable GitHub Pages** in `rabah-khalek/zetanotes`:
   - Settings → Pages
   - Source: Deploy from a branch
   - Branch: `main`
   - Folder: `/docs`

2. **Verify deployment**:
   - Site URL: `https://rabah-khalek.github.io/zetanotes/`
   - Updates appear within 1-2 minutes

## Workflow Monitoring

### Success Indicators

- ✅ Green checkmark in Actions tab
- ✅ Release appears in public repo (Release Workflow)
- ✅ Website updates live (both workflows)

### Troubleshooting

**Release Workflow Fails**:

- Check Xcode build logs
- Verify secrets are set correctly
- Ensure Sparkle keys are valid
- Check public repo permissions

**Website Update Fails**:

- Verify `PUBLIC_REPO_TOKEN` is valid
- Check file permissions in docs/
- Ensure public repo exists and is accessible

**GitHub Pages Not Updating**:

- Check Pages settings in public repo
- Verify docs/ directory exists
- Look for Pages deployment status in public repo

## Best Practices

### Development Workflow

1. **Website changes**: Edit `docs/` files and push to main
2. **App releases**: Use semantic versioning tags (`v1.0.0`)
3. **Testing**: Use manual dispatch for testing workflows

### Version Management

- **Semantic Versioning**: `v1.0.0`, `v1.1.0`, `v1.1.1`
- **Pre-releases**: `v1.0.0-beta.1`, `v1.0.0-rc.1`
- **Hotfixes**: Increment patch version (`v1.0.1`)

### Content Updates

- **Marketing changes**: Use Website Update Workflow
- **Feature documentation**: Include in release notes
- **Bug fix notices**: Can be updated independently

## Security Considerations

- **Never commit secrets** to the repository
- **Rotate tokens** periodically (annually)
- **Monitor workflow logs** for sensitive data exposure
- **Use least privilege** for token permissions

## Monitoring & Alerts

Consider setting up:

- **GitHub notifications** for failed workflows
- **Status badges** in README for workflow status
- **Slack/Discord** webhooks for release notifications

---

**Questions?** Check the workflow logs in GitHub Actions or open an issue.
