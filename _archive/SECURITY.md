# Security & Trust

## How ZetaNotes Protects Your Privacy

ZetaNotes is designed with privacy as the foundation. Here's how we ensure your data stays private:

### 🔒 Complete Offline Operation

- **No network requests**: The app runs entirely offline (except optional model downloads)
- **No analytics**: We don't track usage, crashes, or any user behavior
- **No telemetry**: No data is ever sent to external servers
- **Local storage only**: All notes stored in `~/Library/Application Support/ZetaNotes`

### 🛡️ Verification Steps

You can verify these claims yourself:

**1. Check network activity:**
```bash
# Monitor network connections while using ZetaNotes
sudo lsof -i | grep ZetaNotes
# Should show no active connections during normal use
```

**2. Inspect app permissions:**
```bash
# View what entitlements the app requests
codesign -d --entitlements - /Applications/ZetaNotes.app/Contents/MacOS/ZetaNotes
```

**3. Monitor file system access:**
```bash
# Use tools like:
# - Little Snitch (network monitoring)
# - FSMonitor (file system monitoring)
# - Activity Monitor (system resources)
```

### 🔐 Download Verification

Every release includes SHA256 checksums:

**Verify your download:**
```bash
# Calculate checksum of your downloaded file
shasum -a 256 ~/Downloads/ZetaNotes-v1.0.0.dmg

# Compare with the published checksum in the release notes
```

### ✅ Update Security

Updates use Sparkle framework with EdDSA signatures:

- Each update is cryptographically signed
- Sparkle verifies signatures before installation
- Prevents man-in-the-middle attacks
- Public key embedded in app: `SUPublicEDKey` in Info.plist

### 🔍 What Data Does ZetaNotes Access?

**File System:**
- `~/Library/Application Support/ZetaNotes/` - Note storage (Core Data)
- `~/Library/Application Support/ZetaNotes/models/` - AI model files
- User-selected folders (only when you explicitly choose files)

**System Resources:**
- CPU/GPU for AI inference (Metal acceleration)
- RAM for loading AI models
- No camera, microphone, or location access

**Network (Optional):**
- Only for downloading AI models on first run
- You can manually download models and place them in the models folder

### 🚫 What We DON'T Collect

- ❌ No usage analytics
- ❌ No crash reports
- ❌ No note content
- ❌ No personal information
- ❌ No cookies or tracking
- ❌ No third-party services

### 📋 App Permissions

ZetaNotes requests minimal permissions:

```xml
<!-- From ZetaNotes.entitlements -->
<key>com.apple.security.app-sandbox</key>
<false/>  <!-- Not sandboxed to allow model loading -->

<key>com.apple.security.files.user-selected.read-write</key>
<true/>  <!-- Only for files you explicitly select -->
```

**Note**: The app is not sandboxed to allow loading large AI model files efficiently. This is common for AI applications on macOS.

## Why Isn't ZetaNotes Code Signed?

ZetaNotes is not signed with an Apple Developer certificate to:

1. **Avoid annual $99 fee** - Keep the app free/affordable
2. **Maintain independence** - No Apple Developer account required
3. **User choice** - You decide what to run on your Mac

### Is This Safe?

**Yes, when you verify the source:**

- ✅ Download only from official GitHub releases
- ✅ Verify SHA256 checksums match
- ✅ Check the publisher (rabah-khalek)
- ✅ Read user reviews and community feedback

macOS Gatekeeper warns about unsigned apps as a precaution, not because they're inherently dangerous.

## Opening Unsigned Apps Safely

1. **Right-click** (or Control-Click) on ZetaNotes
2. Select "Open" from the menu
3. Click "Open" in the security dialog
4. Only needed once - subsequent launches work normally

**Alternative method:**
```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine /Applications/ZetaNotes.app
```

## Independent Verification

### VirusTotal Scan

Each release is scanned with VirusTotal:
- [Latest scan results](https://www.virustotal.com) (link will be added per release)

### Community Audit

Technical users can verify:

1. **Network traffic**: Use Little Snitch or Wireshark
2. **File access**: Use FSMonitor or fs_usage
3. **System calls**: Use dtrace or instruments
4. **Memory usage**: Check for data leakage

Share your findings in GitHub Issues!

## Reporting Security Issues

Found a security concern? Please report it:

- **Email**: security@[your-domain].com
- **GitHub Issues**: For non-sensitive issues
- **Expected response**: Within 48 hours

## Trust Building

We're committed to earning your trust through:

- 🔓 **Transparent communication** about privacy practices
- 📖 **Clear documentation** of app behavior
- 🔄 **Regular updates** with detailed changelogs
- 💬 **Responsive support** for user concerns
- 🛡️ **Security-first design** in all features

## Additional Resources

- [Privacy Policy](privacy.html)
- [Terms of Service](terms.html)
- [FAQ](index.html#faq)
- [GitHub Issues](https://github.com/rabah-khalek/zetanotes/issues)

---

**Last Updated**: October 2025
