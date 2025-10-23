# Quick Release Guide

## One-Time Setup

1. **Install tools:**
   ```bash
   brew install create-dmg
   ```

2. **Generate Sparkle keys:**
   ```bash
   ./scripts/setup-sparkle-keys.sh
   ```
   - Public key already in Info.plist ✅
   - Keep private key in Keychain

3. **Set notarization credentials:**
   ```bash
   export APPLE_ID="rabah.khalek@gmail.com"
   export APPLE_TEAM_ID="HDA4C6CU89"
   export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
   ```

   Add to `~/.zshrc` or `~/.bash_profile` for persistence.

## Release Steps

### 1. Build and Notarize

```bash
./scripts/release.sh 1.0.0
```

Wait 1-5 minutes for notarization. Script will:
- ✅ Build app
- ✅ Sign everything (app, Sparkle, libraries, DMG)
- ✅ Generate Sparkle signature
- ✅ Submit for notarization
- ✅ Wait and staple ticket
- ✅ Create all metadata files

### 2. Upload to GitHub

```bash
cd releases/ZetaNotes-Release-YYYYMMDD-HHMMSS/

gh release create v1.0.0 \
  --title "ZetaNotes v1.0.0" \
  --notes "Release notes here" \
  ZetaNotes-v1.0.0.dmg \
  ZetaNotes-v1.0.0.dmg.sha256
```

### 3. Update Appcast

Copy from `ZetaNotes-v1.0.0.dmg.appcast-info` to `docs/appcast.xml`:

```xml
<item>
    <title>Version 1.0.0</title>
    <sparkle:version>1.0.0</sparkle:version>
    <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
    <description><![CDATA[
        <h2>What's New</h2>
        <ul><li>Your changes here</li></ul>
    ]]></description>
    <pubDate>Mon, 21 Oct 2025 12:00:00 +0000</pubDate>
    <enclosure
        url="https://github.com/rabah-khalek/zetanotes/releases/download/v1.0.0/ZetaNotes-v1.0.0.dmg"
        sparkle:version="1.0.0"
        sparkle:shortVersionString="1.0.0"
        length="FILE_SIZE_FROM_INFO"
        type="application/octet-stream"
        sparkle:edSignature="SIGNATURE_FROM_INFO" />
    <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
</item>
```

### 4. Push Appcast

```bash
git add docs/appcast.xml
git commit -m "Release v1.0.0"
git push
```

## That's It!

Users will get update notifications automatically.

## Troubleshooting

**Notarization failed?**
```bash
cat releases/ZetaNotes-Release-*/notarization-failure.json
```

**Check if DMG is notarized:**
```bash
spctl -a -vv -t install ZetaNotes-v1.0.0.dmg
# Should say: source=Notarized Developer ID
```

**Missing Sparkle signature?**
```bash
./scripts/setup-sparkle-keys.sh
# Verify keys exist
```

## Full Documentation

See [RELEASE_WORKFLOW.md](./RELEASE_WORKFLOW.md) for complete details.
