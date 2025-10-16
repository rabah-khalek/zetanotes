# Trust Building Guide for OffNotes

## Closed-Source Software Distribution

Since OffNotes is closed-source paid software, building trust is essential. Here's your step-by-step guide.

---

## ✅ Step 1: Generate VirusTotal Scan (CRITICAL)

**This is the #1 trust signal for closed-source software.**

### After building your DMG

1. Go to <https://www.virustotal.com/>
2. Click "Choose file" and upload `OffNotes-v1.0.0.dmg`
3. Wait for scan (5-10 minutes)
4. Get the public URL (e.g., `https://www.virustotal.com/gui/file/abc123...`)
5. Add this link to your download page

### Update your download.html

```html
<a href="https://www.virustotal.com/gui/file/YOUR_HASH_HERE">
    View VirusTotal Scan →
</a>
```

**Why this matters:** 60+ antivirus engines verify your app is safe. This is HUGE for closed-source trust.

---

## ✅ Step 2: Update Package Script for VirusTotal

Add to `./scripts/package-unsigned.sh` (after DMG creation):

```bash
# At the end of the script, add:
echo ""
echo -e "${YELLOW}📋 Post-Build Checklist:${NC}"
echo ""
echo "1. Upload to VirusTotal:"
echo "   → https://www.virustotal.com/"
echo "   → Upload: ${DMG_NAME}"
echo "   → Save the public scan URL"
echo ""
echo "2. Update download.html with:"
echo "   → VirusTotal link"
echo "   → Checksum: ${CHECKSUM}"
echo ""
echo "3. Test DMG on clean Mac (important!)"
echo ""
echo "4. Create GitHub Release:"
echo "   → Tag: v${VERSION}"
echo "   → Upload DMG and checksum file"
echo "   → Copy INSTALLATION.txt to release notes"
```

---

## ✅ Step 3: Create Privacy Policy Page

Create `docs/privacy.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Privacy Policy - OffNotes</title>
    <style>/* Use same styles as download.html */</style>
</head>
<body>
    <div class="container">
        <h1>Privacy Policy</h1>
        <p><strong>Last Updated: October 16, 2025</strong></p>

        <h2>Our Privacy Philosophy</h2>
        <p>OffNotes was built with one core principle: <strong>Your data is yours, period.</strong></p>

        <h2>What Data We DON'T Collect</h2>
        <ul>
            <li>❌ Your notes (never leave your device)</li>
            <li>❌ Usage analytics or telemetry</li>
            <li>❌ Personal information</li>
            <li>❌ Cookies or tracking</li>
            <li>❌ Crash reports (unless you manually send them)</li>
        </ul>

        <h2>What Data We DO Collect</h2>
        <ul>
            <li>✅ <strong>License Validation (Pro only):</strong> When activating Pro, we verify your license key with Lemon Squeezy (our payment processor). This is a one-time encrypted request.</li>
            <li>✅ <strong>Model Downloads (Optional):</strong> If you download additional AI models, we fetch them from HuggingFace. No tracking.</li>
        </ul>

        <h2>Where Your Data Lives</h2>
        <ul>
            <li><strong>Notes:</strong> Stored locally at <code>~/Library/Application Support/NoteTaker/</code></li>
            <li><strong>AI Models:</strong> Stored locally in app bundle</li>
            <li><strong>Settings:</strong> Stored locally in UserDefaults</li>
        </ul>

        <h2>Third-Party Services</h2>
        <ul>
            <li><strong>Lemon Squeezy:</strong> Payment processing and license validation (Pro tier only)</li>
            <li><strong>HuggingFace:</strong> AI model downloads (optional, Pro tier only)</li>
        </ul>

        <h2>Your Rights</h2>
        <p>You have complete control over your data:</p>
        <ul>
            <li>Delete all data by removing <code>~/Library/Application Support/NoteTaker/</code></li>
            <li>Export notes at any time (File → Export)</li>
            <li>Use OffNotes completely offline after initial setup</li>
        </ul>

        <h2>Changes to This Policy</h2>
        <p>We'll update this page if our privacy practices change. Check back occasionally.</p>

        <h2>Contact</h2>
        <p>Questions? Email: <a href="mailto:support@offnotes.app">support@offnotes.app</a></p>
    </div>
</body>
</html>
```

---

## ✅ Step 4: Add Refund Policy to Lemon Squeezy

In your Lemon Squeezy store settings:

- Set 14-day refund policy
- Add to product description:
  > "14-Day Money-Back Guarantee. If OffNotes doesn't meet your needs, email <support@offnotes.app> for a full refund—no questions asked."

---

## ✅ Step 5: Professional Email Setup

Instead of `support@offnotes.app` from a generic Gmail:

**Option A: Email Forwarding (Free)**

- Use GitHub Pages custom domain
- Set up email forwarding to your Gmail
- Reply from a professional-looking address

**Option B: Professional Email (Paid)**

- Google Workspace: $6/month
- Zoho Mail: $1/month
- ProtonMail: $4/month

---

## ✅ Step 6: Community Launch Strategy

### Week 1: Soft Launch

1. **Product Hunt:** Launch when ready (best on Tuesday-Thursday)
2. **HackerNews:** "Show HN: OffNotes – Private AI note-taking for Mac"
3. **Reddit:**
   - r/macapps
   - r/productivity
   - r/privacytoolsIO
   - r/MacOS

### Post Template

```
Title: "OffNotes – Private AI note-taking that runs 100% offline"

Hey everyone! I built OffNotes after getting frustrated with cloud-based
note apps sending my data to who-knows-where.

What makes it different:
• 100% offline AI (uses local LLMs)
• No cloud sync, no analytics, no tracking
• Free tier with TinyLlama model
• Pro tier: $15 one-time for 8 premium models

I know trust is hard with closed-source software, so I've:
✓ Uploaded to VirusTotal (scanned by 60+ AV engines)
✓ Published SHA-256 checksums
✓ Included 14-day money-back guarantee
✓ Free tier so you can try before buying

VirusTotal: [link]
Download: [link]

Built it primarily for myself but thought others might find it useful.
Happy to answer questions!
```

---

## ✅ Step 7: Build Social Proof

### Add to Website (after 10+ sales)

```html
<div class="testimonials">
    <h2>What Users Are Saying</h2>
    <!-- Collect testimonials from early users -->
</div>

<div class="stats">
    <h3>Trusted by 500+ Users</h3>
    <p>Downloaded 1,000+ times • 4.8/5 rating</p>
</div>
```

### Collect Reviews

- Email users after 1 week: "How's OffNotes working for you?"
- Ask for testimonials (offer small discount for honest review)
- Post on Product Hunt, Reddit, etc.

---

## ✅ Step 8: Transparency Page (Optional but Powerful)

Create `docs/transparency.html`:

```html
<h1>Transparency Report</h1>

<h2>What OffNotes Does Under the Hood</h2>

<h3>Network Requests</h3>
<ul>
    <li>License activation: HTTPS POST to lemonsqueezy.com (one-time)</li>
    <li>Model downloads: HTTPS GET from huggingface.co (optional)</li>
    <li>That's it. No analytics, no telemetry, no tracking.</li>
</ul>

<h3>File System Access</h3>
<ul>
    <li>Reads/writes: ~/Library/Application Support/NoteTaker/</li>
    <li>Read-only: /Applications/OffNotes.app/Contents/Resources/Models/</li>
</ul>

<h3>Permissions Required</h3>
<ul>
    <li>Network Access: Only for model downloads (optional)</li>
    <li>File Access: To save your notes</li>
</ul>

<h2>Trust But Verify</h2>
<p>Want to verify? Use these tools:</p>
<ul>
    <li><strong>Little Snitch:</strong> Monitor all network requests</li>
    <li><strong>Wireshark:</strong> Capture network traffic</li>
    <li><strong>fs_usage:</strong> Monitor file system access</li>
</ul>

<p>We welcome scrutiny. If you find any unexpected behavior,
please email security@offnotes.app immediately.</p>
```

---

## ✅ Step 9: Update Your GitHub README

Add badges and trust signals:

```markdown
# OffNotes

[![License](https://img.shields.io/badge/license-Proprietary-red.svg)]()
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)]()
[![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-Optimized-orange.svg)]()

> **Note:** This is a closed-source commercial product. This repository
> contains documentation and issue tracking only.

## Security & Trust

- ✅ **VirusTotal Verified:** [Scan Results](link)
- ✅ **SHA-256 Checksums:** Published with every release
- ✅ **100% Offline:** No data collection or telemetry
- ✅ **14-Day Refund:** Money-back guarantee

## Download

Visit [offnotes.app](https://your-site.github.io/offnotes/) to download.

---

**Privacy:** We don't collect any data. See [Privacy Policy](privacy.html).
```

---

## 📋 Pre-Launch Checklist

Before publishing your first release:

- [ ] Build DMG with `./scripts/package-unsigned.sh`
- [ ] Test DMG on clean Mac (critical!)
- [ ] Upload to VirusTotal and save link
- [ ] Update download.html with checksum and VirusTotal link
- [ ] Create privacy.html page
- [ ] Set up professional email (or forwarding)
- [ ] Configure Lemon Squeezy refund policy
- [ ] Create GitHub release with DMG and checksums
- [ ] Test license activation flow
- [ ] Prepare launch post for Reddit/HN
- [ ] Set up support email autoresponder

---

## 🎯 Key Messages to Emphasize

1. **"100% Offline"** - Use this phrase everywhere
2. **"No data collection"** - Be explicit
3. **"VirusTotal verified"** - Link prominently
4. **"Try before you buy"** - Free tier reduces risk
5. **"14-day refund"** - Shows confidence in product
6. **"One-time payment"** - Better than subscription

---

## 🚨 What NOT to Do

- ❌ Don't make false claims about "open source"
- ❌ Don't hide the fact that it's unsigned
- ❌ Don't skip the VirusTotal scan
- ❌ Don't ignore user concerns about trust
- ❌ Don't use a Gmail address for support
- ❌ Don't launch without testing on clean Mac

---

## 📊 Measuring Success

Track these metrics:

- Download page visits
- DMG downloads
- License activations
- Support emails (should be low if docs are good)
- Refund requests (should be <5%)

---

## Questions?

This guide should give you everything needed to build trust. Remember:
**Transparency + Verification + Guarantees = Trust**

Good luck with your launch! 🚀
