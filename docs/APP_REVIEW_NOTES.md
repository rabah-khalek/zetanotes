# App Review Information for ZetaNotes

## Sign-In Information

**No sign-in required.** ZetaNotes is a privacy-focused, offline-first app that does not require user accounts.

### Testing Pro Features

To test Pro features during review, use Apple's Sandbox environment:

**Sandbox Testing:**
- ZetaNotes uses **Apple In-App Purchases** (StoreKit 2)
- Use a Sandbox Apple ID to test purchases
- All subscription tiers available in Sandbox mode

### Available Purchase Options

1. **Monthly Subscription**: $1/month
   - Recurring auto-renewable subscription
   - Full access to Pro features

2. **Annual Subscription**: $6/year (Best Value)
   - Recurring auto-renewable subscription
   - Full access to Pro features

3. **Lifetime Purchase**: $20 one-time
   - Non-consumable purchase
   - Permanent access to Pro features

All purchases provide access to:
- 8 open-source AI models (Phi-3, Qwen 2.5, Llama 3.2, Gemma 2, etc.)
- AI Chat Assistant
- Custom AI tools and prompt editing
- Full semantic search capabilities

## Important Notes for Reviewers

### Payment System

This app uses **Apple In-App Purchases** (StoreKit 2) for all transactions.

- ✅ Fully integrated with App Store
- ✅ Sandbox testing enabled
- ✅ Receipt validation implemented
- ✅ "Restore Purchases" supported
- ✅ Subscription management through App Store

###Free Tier Features

The app is fully functional in the free tier with:
- Llama 3.2 1B AI model
- Semantic search
- Translation, grammar check, and reformulation tools
- All note-taking features

### Privacy & Data

- **No account required** - completely local app
- All AI processing happens **offline** on the user's device
- No user data is collected or transmitted
- No analytics or tracking
- Models are downloaded from Hugging Face (open source)

### App Sandbox

**Status:** App Sandbox is **ENABLED** for App Store distribution.

**Special Entitlements Required:**
- The app uses llama.cpp for on-device AI inference
- llama.cpp requires JIT compilation (`com.apple.security.cs.allow-jit`)
- llama.cpp requires unsigned executable memory (`com.apple.security.cs.allow-unsigned-executable-memory`)
- These entitlements are necessary for Metal GPU acceleration

These entitlements are properly declared in the app's entitlements file and are required for the app's core AI functionality.

## Testing Recommendations

### Recommended Test Flow

1. **Free Tier Testing:**
   - Launch app (no purchase required)
   - Create notes and test AI features with Llama 3.2 1B
   - Test semantic search, translation, and grammar tools
   - Verify all basic features work

2. **In-App Purchase Testing:**
   - Click "Upgrade to Pro" button
   - Select a subscription tier
   - Complete purchase in Sandbox
   - Verify Pro features activate

3. **Pro Features Testing:**
   - Switch between different AI models in Settings
   - Test AI Chat feature
   - Edit and customize AI prompts
   - Verify all Pro features work

4. **Restore Purchases:**
   - Use "Restore Purchases" button
   - Verify previous Sandbox purchases are restored

5. **Offline Functionality:**
   - After downloading models, disconnect from internet
   - Verify all AI features work offline
   - Test note creation and search without network

6. **Subscription Management:**
   - Verify "Manage Subscription" links to App Store

## Technical Details

### StoreKit Configuration

Product IDs:
- `com.zetanotes.pro.monthly` - Monthly subscription
- `com.zetanotes.pro.annual` - Annual subscription
- `com.zetanotes.pro.lifetime` - Lifetime purchase (non-consumable)

Subscription Group:
- `ZetaNotes Pro` - Contains monthly and annual subscriptions

### Receipt Validation

- Uses StoreKit 2 built-in verification
- Transactions are verified using `VerificationResult`
- Receipts are validated on-device
- No server-side validation required

## Contact Information

For questions during the review process, please contact:
- **Developer Support:** [Your contact email]
- **App Website:** https://www.zetanotes.com

---

**Build Type:** App Store Submission with In-App Purchases
**Payment Method:** Apple In-App Purchases (StoreKit 2)
**Version:** [Your version number]
**Date:** [Build date]
