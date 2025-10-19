# GitHub Actions Workflows

## Release Workflow

This workflow automates the build and release process for ZetaNotes.

### How it works

1. **Trigger**: Push a tag like `v1.0.0` or manually dispatch with a version number
2. **Build**: Runs the `scripts/release.sh` script to build the app
3. **Sign**: Generates Sparkle EdDSA signature for auto-updates
4. **Release**: Creates a release in the **public `zetanotes` repo** with the DMG
5. **Update**: Updates the `docs/` folder with new appcast.xml and index.html

### Required Secrets

You need to configure these secrets in the repository settings:

#### `PUBLIC_REPO_TOKEN`

- **What**: GitHub Personal Access Token with write access to the public repo
- **How to create**:
  1. Go to <https://github.com/settings/tokens>
  2. Click "Generate new token (classic)"
  3. Give it a descriptive name: "ZetaNotes CI Release Token"
  4. Select scopes:
     - ✅ `repo` (Full control of private repositories)
  5. Click "Generate token"
  6. Copy the token
  7. Go to this repo's Settings → Secrets and variables → Actions
  8. Click "New repository secret"
  9. Name: `PUBLIC_REPO_TOKEN`
  10. Value: Paste the token
  11. Click "Add secret"

#### `SPARKLE_PRIVATE_KEY`

- **What**: EdDSA private key for signing Sparkle updates
- **How to create**:
  1. Download Sparkle's generate_keys tool:

     ```bash
     curl -L https://github.com/sparkle-project/Sparkle/releases/latest/download/generate_keys.tar.xz -o generate_keys.tar.xz
     tar -xf generate_keys.tar.xz
     chmod +x generate_keys
     ```

  2. Generate a key pair:

     ```bash
     ./generate_keys
     ```

  3. It will output:
     - **Private key**: Keep this SECRET! (store in GitHub Secrets)
     - **Public key**: Add to your app's Info.plist
  4. Copy the private key
  5. Go to this repo's Settings → Secrets and variables → Actions
  6. Click "New repository secret"
  7. Name: `SPARKLE_PRIVATE_KEY`
  8. Value: Paste the ENTIRE private key (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
  9. Click "Add secret"
  10. Add the public key to `ZetaNotes/Info.plist`:

     ```xml
     <key>SUPublicEDKey</key>
     <string>YOUR_PUBLIC_KEY_HERE</string>
     ```

### Usage

#### Option 1: Tag-based release (Recommended)

```bash
# Tag the commit
git tag v1.0.0

# Push the tag
git push origin v1.0.0
```

The workflow will automatically:

- Build the app
- Create a release in the public repo
- Update the GitHub Pages

#### Option 2: Manual dispatch

1. Go to Actions → "Build and Release to Public Repo"
2. Click "Run workflow"
3. Enter the version number (e.g., `1.0.0`)
4. Click "Run workflow"

### What Gets Created

1. **Public repo release**: <https://github.com/rabah-khalek/zetanotes/releases>
   - DMG file
   - SHA256 checksum
   - Installation instructions

2. **Updated docs/**:
   - `appcast.xml` with new version info
   - `index.html` with updated download link

3. **GitHub Pages**: <https://rabah-khalek.github.io/zetanotes/>
   - Auto-deploys from the `docs/` folder

### Troubleshooting

#### "Resource not accessible by integration"

- Check that `PUBLIC_REPO_TOKEN` is set correctly
- Ensure the token has `repo` scope

#### "Signature generation failed"

- Check that `SPARKLE_PRIVATE_KEY` is set correctly
- Ensure the key is the complete private key including headers

#### "Build failed"

- Check the build logs
- Ensure Xcode is set up correctly
- Verify `scripts/release.sh` works locally

### Local Testing

Before pushing a tag, test locally:

```bash
# Test the build script
./scripts/release.sh 1.0.0

# Verify the DMG was created
# It should be in ~/Desktop/ZetaNotes-Release-*/
```

### Architecture

```
Developer → Push tag to zetanotes-dev (this repo)
            ↓
    GitHub Actions builds in -dev
            ↓
    Creates release in PUBLIC zetanotes repo
            ↓
    Updates docs/ in zetanotes repo
            ↓
    GitHub Pages auto-deploys
            ↓
    Users visit https://rabah-khalek.github.io/zetanotes/
```

### Public Repo Setup

The public `zetanotes` repo should have:

1. **GitHub Pages enabled**:
   - Settings → Pages
   - Source: Deploy from branch
   - Branch: `main`
   - Folder: `/docs`

2. **Minimal structure**:

   ```
   zetanotes/
   ├── docs/               # GitHub Pages content (updated by CI)
   │   ├── index.html
   │   ├── appcast.xml
   │   └── logo.png
   ├── README.md           # Download instructions
   └── LICENSE
   ```

3. **No source code**: Keep all source code in the private `-dev` repo
