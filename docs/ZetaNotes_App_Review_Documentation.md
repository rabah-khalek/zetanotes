# ZetaNotes - App Review Documentation

**App Name:** ZetaNotes
**Bundle ID:** com.zetanotes
**Version:** 1.0.0
**Category:** Productivity
**Platform:** macOS

---

## App Overview

ZetaNotes is a privacy-focused, offline AI-powered note-taking application for macOS. The app features intelligent autocomplete, summarization, translation, and semantic search - all running privately on the user's device using portable Large Language Models (LLMs).

### Key Features

- **Offline AI Processing**: All AI computations run locally using llama.cpp with Metal GPU acceleration
- **8 AI Models**: Pro users access multiple open-source models (Phi-3, Qwen 2.5, Llama 3.2, Gemma 2, etc.)
- **AI Chat Assistant**: Natural conversations with AI using selected models
- **Custom Tools**: Create and customize AI-powered tools for specific workflows
- **Semantic Search**: Intelligent search across notes using AI embeddings
- **Privacy-First**: No data collection, no analytics, no cloud processing

---

## App Review Build Configuration

**This is a special App Review build with Pro features pre-enabled.**

The submitted build includes the `DEV_PRO_MODE` compiler flag in its Debug configuration, which:

- Automatically enables Pro/Lifetime tier on app launch
- Grants access to all 8 AI models
- Unlocks AI Chat and custom tool features
- Does NOT affect production Release builds (flag not present in Release)

This allows reviewers to thoroughly test all Pro features without requiring StoreKit sandbox purchases.

**For Production:** The Release configuration does NOT include `DEV_PRO_MODE`, so end users will need to purchase to access Pro features normally.

## Demo Video (if applicable)

A comprehensive demo video can show:
- App installation and first launch
- Pro features (pre-enabled in this build)
- Model switching, AI chat, custom prompts
- In-app purchase UI (functional but not required for Pro access)
- Offline functionality

---

## Testing Instructions for Reviewers

### No Sign-In Required

ZetaNotes is a **local-first application** with no user account system. No credentials are needed to launch and use the app.

### App Review Build - Pro Features Pre-Enabled

**Important:** This build has been configured specifically for App Review with **Pro features already enabled**.

The Debug build includes the `DEV_PRO_MODE` compiler flag, which automatically grants Pro/Lifetime access without requiring any purchase. This allows you to:

✅ Test all Pro features immediately upon launch
✅ Switch between all 8 AI models
✅ Access AI Chat
✅ Create and customize AI tools
✅ Verify the full Pro experience

**No purchase necessary** - you can test all Pro features directly.

### Testing In-App Purchases (Optional)

While Pro features are pre-enabled in this build, you can still test the purchase flow if desired using **Apple's StoreKit Configuration file** (`Configuration.storekit`):

#### Available Purchase Options:

1. **Monthly Subscription** - $1/month
   - Auto-renewable subscription
   - Product ID: `com.zetanotes.pro.month`

2. **Annual Subscription** - $6/year
   - Auto-renewable subscription
   - Product ID: `com.zetanotes.pro.annual`
   - Best value option

3. **Lifetime Purchase** - $20.00 one-time
   - Non-consumable purchase
   - Product ID: `com.zetanotes.pro.lifetime`

**Note:** Since Pro is already enabled in this build, purchasing will not change functionality, but you can verify the purchase UI works correctly.

### Testing Pro Features

The following Pro features are available immediately:

1. **Model Switching**:
   - Go to Settings → AI Settings
   - Switch between 8 available AI models
   - Test different models in note-taking

2. **AI Chat**:
   - Access AI Chat from menu or toolbar
   - Have conversations with the selected model
   - Test chat history and context

3. **Custom Prompts**:
   - Go to Settings → Prompts
   - Edit existing prompts
   - Create custom AI tools
   - Test custom prompts in notes

4. **All Pro Models Available**:
   - TinyLlama 1.1B
   - Llama 3.2 1B & 3B
   - Qwen2.5 1.5B & 3B
   - SmolLM2 1.7B
   - Phi-2 2.7B
   - Gemma 2 2B
   - Phi-3.5 Mini 3.8B

---

## Important Technical Information

### App Sandbox

**Status:** App Sandbox is **ENABLED** as required for App Store distribution.

**Special Entitlements Required:**

ZetaNotes uses **llama.cpp** for on-device AI inference, which requires:

- `com.apple.security.cs.allow-jit` - JIT compilation for Metal GPU acceleration
- `com.apple.security.cs.allow-unsigned-executable-memory` - Dynamic model loading

These entitlements are **essential** for the app's core AI functionality. Without them, AI features cannot work.

**Technical Justification:**
- llama.cpp is an industry-standard framework for running LLMs locally
- Metal GPU acceleration requires JIT compilation for optimal performance
- Dynamic model loading requires unsigned executable memory
- All AI processing happens offline on the user's device for privacy

### Privacy & Data Collection

ZetaNotes is designed with privacy as a top priority:

- ✅ **No user accounts** - completely local app
- ✅ **No data collection** - no analytics, no tracking
- ✅ **No cloud processing** - all AI runs on-device
- ✅ **No network requests** except:
  - Downloading AI models from Hugging Face (user-initiated)
  - In-App Purchase communication with App Store

### AI Models Source

All AI models are:
- Open-source models from Hugging Face
- Downloaded directly from Hugging Face CDN
- Stored locally in user's Application Support folder
- Never uploaded or shared

### Subscription Management

- Subscriptions managed through App Store
- Users can cancel/manage via App Store settings
- "Manage Subscription" links directly to App Store
- Family Sharing supported for all purchases

---

## Common Review Questions Answered

### Why does the app need JIT and unsigned memory entitlements?

The app uses **llama.cpp**, an industry-standard C++ library for running Large Language Models locally. llama.cpp requires:

1. **JIT Compilation** - to compile optimized Metal shaders at runtime for GPU acceleration
2. **Unsigned Memory** - to load AI models dynamically into memory

These are standard requirements for any app running LLMs locally and are used by many AI applications on the App Store.

### Is this app safe with these entitlements?

Yes. The entitlements are used exclusively for:
- Loading and running AI models (llama.cpp library)
- GPU acceleration via Metal framework
- No arbitrary code execution
- No downloading/running of external code

### How large are the AI models?

Models range from ~700MB to ~2GB each:
- Free tier: Llama 3.2 1B (~700MB)
- Pro models: Range from 1-2GB each
- Users choose which models to download
- Models stored in Application Support

### Can the app work offline?

Yes, completely:
- After initial model download, no internet required
- All AI processing happens on-device
- Notes stored locally in SQLite database
- Perfect for privacy-conscious users

### What about updates?

Updates are delivered automatically through the **Mac App Store**:
- Users receive updates through System Settings → Software Update
- Apple handles all update distribution and verification
- No additional update mechanism required

---

## Testing Checklist for Reviewers

We recommend testing these scenarios:

- [ ] Launch app - Pro features immediately available (no purchase needed)
- [ ] Create and edit notes
- [ ] Test AI features with default Llama 3.2 1B model
- [ ] **Test model switching** - switch between all 8 available Pro models
- [ ] **Test AI Chat feature** - have conversations with the AI
- [ ] **Test custom prompt editing** - create and modify AI tools
- [ ] Verify Settings → License shows "Lifetime" status (dev mode)
- [ ] Test offline functionality (disconnect network after model download)
- [ ] Verify no crashes or unexpected behavior
- [ ] (Optional) Test purchase UI flow with StoreKit Configuration

---

## Support Information

**Developer:** Rabah Abdul Khalek
**Website:** https://www.zetanotes.com
**Support Email:** [Your support email]

**App Store Connect Team ID:** HDA4C6CU89

---

## Additional Notes

### Important: App Review Build vs Production Build

**This submitted build is configured for App Review purposes:**

- **Debug configuration** (for App Review): Includes `DEV_PRO_MODE` flag → Pro features enabled by default
- **Release configuration** (for end users): Does NOT include `DEV_PRO_MODE` → Requires purchase for Pro

This ensures reviewers can thoroughly test all Pro features, while production users experience the normal purchase flow. The code checks for the `DEV_PRO_MODE` compiler flag and only enables free Pro access when present.

**Production behavior:** When users download from the App Store, they will receive the Release build without `DEV_PRO_MODE`, requiring them to purchase subscriptions to access Pro features as designed.

### Subscription Tiers Strategy

The app offers three purchasing options to accommodate different user preferences:

1. **Monthly** - For users who want to try Pro features with low commitment
2. **Annual** - Best value for committed users (saves 50% vs monthly)
3. **Lifetime** - One-time purchase for users who prefer ownership

All tiers provide identical feature access.

### Free Tier Rationale

The free tier includes:
- Full note-taking functionality
- One AI model (Llama 3.2 1B)
- Basic AI features (search, translation, grammar)

This allows users to experience the app's value before upgrading, leading to higher conversion rates and better user satisfaction.

### Privacy Commitment

ZetaNotes is built for users who value privacy:
- No analytics or crash reporting (by design)
- No user tracking
- No data ever leaves the device
- All processing is local

This is a core value proposition and competitive differentiator.

---

## Conclusion

ZetaNotes is a fully-featured, production-ready application that:

✅ Follows all App Store guidelines
✅ Uses native Apple In-App Purchases
✅ Requires App Sandbox with justified entitlements
✅ Provides exceptional value to users
✅ Prioritizes user privacy
✅ Works completely offline after setup

We appreciate your time reviewing this application and are available to answer any questions during the review process.

---

**Document Version:** 1.0.0
**Date:** January 2025
**Prepared for:** Apple App Review Team
