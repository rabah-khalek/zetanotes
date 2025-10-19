# Paddle & Sparkle Setup Guide

This guide will walk you through setting up Paddle for payments and Sparkle for auto-updates in ZetaNotes.

## 🚣 Paddle Setup (Payment Processing)

### 1. Create Paddle Account

1. **Sign Up**: Go to [paddle.com](https://paddle.com) and create an account
2. **Verify Email**: Complete email verification
3. **Business Information**: Fill out your business details
   - Business name: "ZetaNotes" or your company name
   - Business type: Individual/LLC/Corporation
   - Tax information (Paddle handles tax compliance automatically)
   - Bank account details for payouts

### 2. Create Your Products

1. **Catalog** → **Products** → **Create Product**
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
   - **Type**: Software/SaaS
   - **Tax category**: Software

### 3. Create Pricing Plans

#### Monthly Plan
1. **Catalog** → **Prices** → **Create Price**
2. **Price Details**:
   - **Product**: ZetaNotes Pro
   - **Name**: `Monthly Plan`
   - **Billing cycle**: Monthly
   - **Price**: $1.00 USD
   - **Trial period**: 7 days (optional)

#### Annual Plan
1. **Create Price** (repeat process)
2. **Price Details**:
   - **Product**: ZetaNotes Pro
   - **Name**: `Annual Plan`
   - **Billing cycle**: Yearly
   - **Price**: $6.00 USD (50% discount vs monthly)

#### Lifetime Plan
1. **Create Price** (repeat process)
2. **Price Details**:
   - **Product**: ZetaNotes Pro
   - **Name**: `Lifetime License`
   - **Billing cycle**: One-time
   - **Price**: $20.00 USD

### 4. Set Up Webhooks

1. **Developer Tools** → **Notifications** → **Destination**
2. **Add Destination**:
   - **Endpoint URL**: `https://your-server.com/webhooks/paddle`
   - **Description**: ZetaNotes License Management
3. **Select Events**:
   - ✅ `transaction.completed`
   - ✅ `subscription.created`
   - ✅ `subscription.updated`
   - ✅ `subscription.canceled`

### 5. Get API Keys

1. **Developer Tools** → **Authentication**
2. **Create API Key**:
   - **Name**: `ZetaNotes Backend`
   - **Scopes**:
     - ✅ Read transactions
     - ✅ Read subscriptions
     - ✅ Read customers
3. **Save both keys**:
   - **Client-side key**: For Paddle.js (public)
   - **Server-side key**: For API calls (secret)

### 6. Integrate Paddle Checkout

#### HTML/JavaScript Integration:
```html
<!-- Paddle.js -->
<script src="https://cdn.paddle.com/paddle/v2/paddle.js"></script>

<script>
Paddle.Environment.set('production'); // or 'sandbox' for testing
Paddle.Initialize({
  token: 'YOUR_CLIENT_SIDE_TOKEN'
});

// Open checkout for monthly plan
function buyMonthly() {
  Paddle.Checkout.open({
    items: [{ priceId: 'pri_monthly_price_id', quantity: 1 }],
    customer: {
      email: 'customer@example.com' // Optional pre-fill
    },
    customData: {
      app: 'zetanotes',
      version: '1.0'
    }
  });
}

// Open checkout for lifetime plan
function buyLifetime() {
  Paddle.Checkout.open({
    items: [{ priceId: 'pri_lifetime_price_id', quantity: 1 }]
  });
}
</script>
```

### 7. Webhook Handler Example

```javascript
// Webhook handler (Node.js/Vercel/Netlify)
export default async function handler(req, res) {
  const signature = req.headers['paddle-signature'];

  // Verify webhook signature
  if (!verifyPaddleSignature(req.body, signature)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const event = req.body;

  if (event.event_type === 'transaction.completed') {
    const transaction = event.data;

    // Generate license key
    const licenseKey = generateLicense(transaction.customer_email);

    // Store license
    await saveLicense({
      email: transaction.customer_email,
      license: licenseKey,
      paddleTransactionId: transaction.id,
      product: transaction.items[0].product.name,
      amount: transaction.details.totals.total,
      createdAt: new Date()
    });

    // Send license email
    await sendLicenseEmail(transaction.customer_email, licenseKey);
  }

  if (event.event_type === 'subscription.canceled') {
    // Handle subscription cancellation
    await deactivateLicense(event.data.customer_email);
  }

  res.json({ received: true });
}

function generateLicense(email) {
  const uuid = crypto.randomUUID().replace(/-/g, '').toUpperCase();
  return `ZETA-${uuid.slice(0,4)}-${uuid.slice(4,8)}-${uuid.slice(8,12)}`;
}
```

### 8. License Validation

```javascript
// /api/validate endpoint
export default async function handler(req, res) {
  const { license, email } = req.body;

  const record = await database.licenses.findFirst({
    where: {
      key: license,
      email: email,
      active: true
    }
  });

  if (record) {
    // Check if subscription is still active (for recurring plans)
    let isActive = true;
    if (record.paddleSubscriptionId) {
      isActive = await checkPaddleSubscriptionStatus(record.paddleSubscriptionId);
    }

    res.json({
      valid: isActive,
      features: ['pro', 'chat', 'models', 'custom-tools'],
      plan: record.product,
      expiresAt: record.expiresAt
    });
  } else {
    res.json({ valid: false });
  }
}
```

### 9. Testing

#### Sandbox Mode:
1. **Developer Tools** → **Environment** → Switch to **Sandbox**
2. Use test card numbers:
   - **Success**: `4000 0000 0000 0002`
   - **Decline**: `4000 0000 0000 0341`
3. Test webhook delivery in sandbox environment

#### Go Live:
1. **Complete verification** process with Paddle
2. **Switch to Production** environment
3. **Update client-side token** in your checkout code

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

### 1. Test Paddle Integration

1. **Create test product** in Paddle Sandbox mode
2. **Make test purchase** with test card: `4000 0000 0000 0002`
3. **Verify webhook** receives transaction data
4. **Test license validation** in your app

### 2. Test Sparkle Updates

1. **Push a git tag** to zetanotes-dev: `git tag v1.0.1 && git push origin v1.0.1`
2. **Watch GitHub Actions** build and deploy
3. **Check zetanotes-repo** for new release
4. **Verify appcast.xml** is updated
5. **Test app update** flow

### 3. End-to-End Test

1. **Install app** from DMG
2. **Purchase Pro license** (sandbox mode)
3. **Activate license** in app
4. **Trigger update check**
5. **Verify auto-update** works

---

## 🚀 Going Live Checklist

### Paddle

- [ ] Complete business verification with Paddle
- [ ] Switch from Sandbox to Production environment
- [ ] Set up real bank account for payouts
- [ ] Configure tax settings (handled automatically by Paddle)
- [ ] Test real payment flow with small amount
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

### Paddle

- **Documentation**: [developer.paddle.com](https://developer.paddle.com)
- **Support**: [paddle.com/support](https://paddle.com/support)
- **Community**: [Paddle Community](https://community.paddle.com)

### Sparkle

- **Documentation**: [sparkle-project.org/documentation](https://sparkle-project.org/documentation)
- **GitHub**: [github.com/sparkle-project/Sparkle](https://github.com/sparkle-project/Sparkle)
- **Issues**: GitHub Issues for technical problems

---

## 🔒 Security Best Practices

### Paddle

- **Never expose server-side API keys** in client-side code
- **Validate webhooks** with signature verification
- **Use HTTPS** for all webhook endpoints
- **Log and monitor** payment events
- **Keep client-side tokens** separate from server-side keys

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

## 💰 Paddle vs Other Platforms

### Paddle Advantages:

- **Merchant of Record**: Handles all tax compliance (VAT, sales tax)
- **Global Coverage**: 200+ countries supported
- **Better Fees**: ~5% total (competitive with LemonSqueezy)
- **Advanced Features**: Dunning management, revenue recovery
- **Professional Platform**: Trusted by major software companies

### Why Paddle for ZetaNotes:

- **Tax Compliance**: Automatic handling of EU VAT, US sales tax
- **International Sales**: Global customer support
- **Recovery Tools**: Reduce churn with smart retry logic
- **Reporting**: Detailed analytics and financial reporting
- **Developer Experience**: Well-documented API and webhooks

---

**Questions?** Open an issue in zetanotes-dev or contact support at your configured email address.
