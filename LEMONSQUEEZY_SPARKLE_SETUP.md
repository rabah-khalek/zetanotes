# LemonSqueezy & Sparkle Setup Guide

This guide will walk you through setting up LemonSqueezy for payments and Sparkle for auto-updates in ZetaNotes.

## 🍋 LemonSqueezy Setup (Payment Processing)

### 1. Create LemonSqueezy Account

1. **Sign Up**: Go to [lemonsqueezy.com](https://lemonsqueezy.com) and create an account
2. **Verify Email**: Complete email verification
3. **Business Information**: Fill out your business details
   - Business name: "ZetaNotes" or your company name
   - Business type: Individual/LLC/Corporation
   - Tax information (required for payouts)

### 2. Create Your Store

1. **Dashboard** → **Stores** → **Create Store**
2. **Store Details**:
   - Store name: `ZetaNotes`
   - Store slug: `zetanotes`
   - Currency: `USD` (or your preferred currency)
   - Store description: `Offline AI note-taking for macOS`

### 3. Set Up Products

#### Create the Pro License Product

1. **Products** → **New Product**
2. **Product Information**:
   - **Name**: `ZetaNotes Pro`
   - **Description**:

     ```
     Unlock all Pro features in ZetaNotes:
     - 8 open-source AI models (Phi-3, Qwen 2.5, Llama 3.2, Gemma 2 & more)
     - AI Chat Assistant
     - Create custom AI tools
     - Customize all prompts and settings
     - Priority support
     ```

   - **Category**: Software
   - **Product type**: Digital product

#### Create Variants (Pricing Plans)

1. **Add Variant**: Monthly Plan
   - **Name**: `Monthly`
   - **Price**: `$1.00`
   - **Billing**: `Recurring monthly`
   - **Trial**: 7 days (optional)

2. **Add Variant**: Annual Plan
   - **Name**: `Annual`
   - **Price**: `$6.00`
   - **Billing**: `Recurring yearly`
   - **Discount tag**: `50% off`

3. **Add Variant**: Lifetime Plan
   - **Name**: `Lifetime`
   - **Price**: `$20.00`
   - **Billing**: `One-time`

### 4. Configure Checkout Settings

1. **Product Settings** → **Checkout**:
   - **Collect customer name**: ✅ Required
   - **Collect customer email**: ✅ Required
   - **Custom fields**: Add "License Email" field
   - **Thank you page**: Custom message with license activation instructions

### 5. Set Up Webhooks (Important!)

1. **Settings** → **Webhooks** → **Add Endpoint**
2. **Webhook URL**: `https://your-server.com/webhooks/lemonsqueezy`
3. **Events to listen for**:
   - ✅ `order_created`
   - ✅ `subscription_created`
   - ✅ `subscription_updated`
   - ✅ `subscription_cancelled`

### 6. Get API Credentials

1. **Settings** → **API** → **Create API Key**
2. **Name**: `ZetaNotes License Management`
3. **Permissions**:
   - ✅ Read orders
   - ✅ Read subscriptions
   - ✅ Read customers
4. **Save the API key** - you'll need it for license validation

### 7. Test Mode vs Live Mode

- **Test Mode**: Use for development and testing
- **Live Mode**: Switch when ready for real customers
- Always test thoroughly in test mode first!

---

## ⚡ Sparkle Framework Setup (Auto-Updates)

### 1. Generate EdDSA Key Pair

```bash
# Navigate to your project directory
cd /path/to/zetanotes-dev

# Create a directory for Sparkle keys (keep this secure!)
mkdir -p ~/.sparkle-keys

# Generate EdDSA key pair
# Download generate_keys tool first:
curl -L https://github.com/sparkle-project/Sparkle/releases/latest/download/generate_keys.tar.xz -o /tmp/generate_keys.tar.xz
tar -xf /tmp/generate_keys.tar.xz -C /tmp
chmod +x /tmp/generate_keys

# Generate the keys
/tmp/generate_keys ~/.sparkle-keys/zetanotes_ed25519
```

This creates two files:

- `~/.sparkle-keys/zetanotes_ed25519` (private key - keep secret!)
- `~/.sparkle-keys/zetanotes_ed25519.pub` (public key - embed in app)

### 2. Add Public Key to Your App

1. **Open** `ZetaNotes/Info.plist`
2. **Add** the following key with your public key:

```xml
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

3. **Get your public key**:

```bash
cat ~/.sparkle-keys/zetanotes_ed25519.pub
```

### 3. Configure Sparkle in Your App

#### In `Info.plist`, add

```xml
<!-- Sparkle Configuration -->
<key>SUFeedURL</key>
<string>https://rabah-khalek.github.io/zetanotes/appcast.xml</string>

<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_FROM_STEP_2</string>

<key>SUEnableAutomaticChecks</key>
<true/>

<key>SUScheduledCheckInterval</key>
<integer>86400</integer>

<key>SUAllowsAutomaticUpdates</key>
<true/>
```

#### In your SwiftUI app, add Sparkle

```swift
import Sparkle

@main
struct ZetaNotesApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterController.updater.checkForUpdates()
                }
            }
        }
    }
}
```

### 4. Test Sparkle Integration

1. **Build** your app with Sparkle integrated
2. **Create** a test appcast.xml with a higher version number
3. **Run** the app and test "Check for Updates"
4. **Verify** the update flow works correctly

---

## 🔑 GitHub Secrets Setup

Add these secrets to your **zetanotes-dev** repository (Settings → Secrets and Variables → Actions):

### 1. PUBLIC_REPO_TOKEN

1. **GitHub** → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. **Generate new token (classic)**
3. **Scopes**:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
4. **Name**: `ZetaNotes Public Repo Access`
5. **Copy the token** and add as `PUBLIC_REPO_TOKEN` secret

### 2. SPARKLE_PRIVATE_KEY

```bash
# Copy your private key content
cat ~/.sparkle-keys/zetanotes_ed25519
```

Add the entire private key content (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`) as the `SPARKLE_PRIVATE_KEY` secret.

---

## 🧪 Testing the Complete Flow

### 1. Test LemonSqueezy Integration

1. **Create test product** in LemonSqueezy test mode
2. **Make test purchase** with test card: `4242 4242 4242 4242`
3. **Verify webhook** receives order data
4. **Test license validation** in your app

### 2. Test Sparkle Updates

1. **Push a git tag** to zetanotes-dev: `git tag v1.0.1 && git push origin v1.0.1`
2. **Watch GitHub Actions** build and deploy
3. **Check zetanotes-repo** for new release
4. **Verify appcast.xml** is updated
5. **Test app update** flow

### 3. End-to-End Test

1. **Install app** from DMG
2. **Purchase Pro license** (test mode)
3. **Activate license** in app
4. **Trigger update check**
5. **Verify auto-update** works

---

## 🚀 Going Live Checklist

### LemonSqueezy

- [ ] Switch from test mode to live mode
- [ ] Set up real bank account for payouts
- [ ] Configure tax settings for your jurisdiction
- [ ] Test real payment flow
- [ ] Set up customer support email

### Sparkle

- [ ] Verify public key is correctly embedded in app
- [ ] Test appcast.xml is accessible publicly
- [ ] Confirm EdDSA signatures are working
- [ ] Test update flow on different macOS versions

### GitHub

- [ ] Verify all secrets are set correctly
- [ ] Test CI pipeline with a real release
- [ ] Confirm GitHub Pages is working
- [ ] Check download links are functional

---

## 📞 Support Resources

### LemonSqueezy

- **Documentation**: [docs.lemonsqueezy.com](https://docs.lemonsqueezy.com)
- **Support**: [lemonsqueezy.com/help](https://lemonsqueezy.com/help)
- **Community**: [Discord](https://discord.gg/lemonsqueezy)

### Sparkle

- **Documentation**: [sparkle-project.org/documentation](https://sparkle-project.org/documentation)
- **GitHub**: [github.com/sparkle-project/Sparkle](https://github.com/sparkle-project/Sparkle)
- **Issues**: GitHub Issues for technical problems

---

## 🔒 Security Best Practices

### LemonSqueezy

- **Never expose API keys** in client-side code
- **Validate webhooks** with signature verification
- **Use HTTPS** for all webhook endpoints
- **Log and monitor** payment events

### Sparkle

- **Keep private key secure** - never commit to git
- **Use environment variables** for CI/CD
- **Rotate keys periodically** (annually)
- **Monitor update adoption** rates

### General

- **Regular backups** of keys and configurations
- **Access control** - limit who has access to production secrets
- **Audit logs** - track access to sensitive operations
- **Incident response plan** - know what to do if keys are compromised

---

**Questions?** Open an issue in zetanotes-dev or contact support at your configured email address.
