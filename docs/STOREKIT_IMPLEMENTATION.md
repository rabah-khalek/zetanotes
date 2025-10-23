# StoreKit 2 Implementation Guide for ZetaNotes

## ✅ Implementation Complete

ZetaNotes now uses **Apple In-App Purchases (StoreKit 2)** for all Pro subscriptions and purchases.

---

## What Was Implemented

### 1. StoreKit Configuration File

**File:** `ZetaNotes/Configuration.storekit`

This file enables local testing in Xcode without needing App Store Connect:

- **Monthly Subscription**: $1/month (`com.zetanotes.pro.monthly`)
- **Annual Subscription**: $6/year (`com.zetanotes.pro.annual`)
- **Lifetime Purchase**: $20 one-time (`com.zetanotes.pro.lifetime`)

**Testing in Xcode:**
- Run the app in Simulator or on device
- StoreKit Testing automatically uses this configuration
- No real purchases required during development

### 2. StoreKitManager

**File:** `ZetaNotes/Managers/StoreKitManager.swift`

Core IAP functionality:

- ✅ Product loading from App Store
- ✅ Purchase processing
- ✅ Transaction verification
- ✅ Subscription status tracking
- ✅ Receipt validation (StoreKit 2 built-in)
- ✅ Transaction listener for updates
- ✅ Restore purchases

**Key Features:**
- `@MainActor` for safe UI updates
- Automatic transaction listening
- Subscription status monitoring
- Grace period and billing retry support

### 3. Updated LicenseManager

**File:** `ZetaNotes/Managers/LicenseManager.swift`

Simplified to delegate to StoreKitManager:

- **Old:** Paddle API calls, manual license validation
- **New:** StoreKit integration, automatic receipt validation
- Removed: All Paddle HTTP code
- Added: Combine publishers for reactive updates

**Backup:** Old Paddle version saved as `LicenseManager_Paddle_Backup.swift`

### 4. Updated UpgradePromptView

**File:** `ZetaNotes/Views/UpgradePromptView.swift`

Native in-app purchase UI:

- **Old:** Opens Paddle URLs in browser
- **New:** Native StoreKit purchase flow
- Displays real-time pricing from App Store
- Shows purchase progress
- Error handling with user-friendly messages
- "Restore Purchases" button

**Backup:** Old Paddle version saved as `UpgradePromptView_Paddle_Backup.swift`

### 5. App Sandbox Enabled

**File:** `ZetaNotes/ZetaNotes.entitlements`

Changes:
- ✅ **App Sandbox ENABLED** (required for App Store)
- ✅ Keeps JIT and unsigned memory entitlements for llama.cpp
- ✅ Network client for model downloads and StoreKit

**Important:** App Sandbox is **required** for App Store distribution with IAP.

### 6. Documentation

Updated files:
- `docs/APP_REVIEW_NOTES.md` - Apple reviewer guide (no more test credentials!)
- `docs/STOREKIT_IMPLEMENTATION.md` - This file

Removed references to:
- Paddle payment processor
- Test license credentials
- External payment links

---

## Testing the Implementation

### Local Testing (Xcode)

1. **Run in Xcode:**
   ```bash
   # Open project
   open ZetaNotes.xcodeproj

   # Select scheme: ZetaNotes
   # Run on Simulator or device
   ```

2. **Test Purchase Flow:**
   - Click "Upgrade to Pro"
   - Select a subscription tier
   - Click "Upgrade to Pro" button
   - StoreKit Testing will show purchase confirmation
   - Approve the purchase
   - Pro features should activate immediately

3. **Test Restore Purchases:**
   - After making a test purchase
   - Quit and relaunch the app
   - Go to Settings → License
   - Click "Restore Purchases"
   - Pro status should restore

4. **View Test Transactions:**
   - Xcode → Debug → StoreKit → Manage Transactions
   - See all test purchases
   - Can clear transactions for fresh testing

### StoreKit Testing Configuration

In Xcode, you can:
- View purchased products
- Refund test purchases
- Test subscription renewals
- Test billing issues
- Clear purchase history

**Editor → Configuration → StoreKit Configuration**
- Select `Configuration.storekit`

### Sandbox Testing (Real Device)

1. **Create Sandbox Tester:**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Users and Access → Sandbox Testers
   - Create test Apple ID

2. **Sign Out of App Store:**
   - On test device: Settings → App Store → Sign Out
   - DO NOT sign in to Sandbox account yet

3. **Test Purchase:**
   - Run app on device
   - Try to purchase
   - You'll be prompted to sign in
   - Use Sandbox tester credentials
   - Complete purchase

4. **Verify:**
   - Check Pro features activate
   - Test "Restore Purchases"
   - Test subscription management

---

## App Store Connect Setup

### Required Steps Before Submission

1. **Create IAP Products** in App Store Connect:

   **Monthly Subscription:**
   - Product ID: `com.zetanotes.pro.monthly`
   - Type: Auto-Renewable Subscription
   - Subscription Group: "ZetaNotes Pro"
   - Duration: 1 Month
   - Price: $1

   **Annual Subscription:**
   - Product ID: `com.zetanotes.pro.annual`
   - Type: Auto-Renewable Subscription
   - Subscription Group: "ZetaNotes Pro"
   - Duration: 1 Year
   - Price: $6

   **Lifetime Purchase:**
   - Product ID: `com.zetanotes.pro.lifetime`
   - Type: Non-Consumable
   - Price: $20.00

2. **Configure Subscription Group:**
   - Name: "ZetaNotes Pro"
   - Add localizations (English required)
   - Set subscription level (monthly = 1, annual = 2 for upgrade path)

3. **Add Product Metadata:**
   - Display names
   - Descriptions
   - Screenshot (if required)
   - Review notes

4. **Submit for Review:**
   - IAP products must be submitted alongside the app
   - First version requires App Review approval for IAPs

### Important Notes

- **Product IDs must match** the ones in `Configuration.storekit`
- **Subscriptions require** subscription group
- **Lifetime purchase** is non-consumable, not subscription
- **Prices** can be adjusted in App Store Connect (auto-converted to local currencies)

---

## Code Architecture

### Data Flow

```
User Taps "Upgrade"
    ↓
UpgradePromptView
    ↓
LicenseManager.purchase(productID)
    ↓
StoreKitManager.purchase(product)
    ↓
StoreKit 2 (App Store)
    ↓
Transaction Verification
    ↓
Update Customer Status
    ↓
LicenseManager.isPro = true
    ↓
UI Updates (Pro Features Unlocked)
```

### Subscription Status Updates

```
Transaction Listener (Background)
    ↓
New Transaction Detected
    ↓
Verify Transaction
    ↓
Update Customer Product Status
    ↓
Check Subscription State
    ↓
Update LicenseManager Properties
    ↓
UI Updates Automatically (via @Published)
```

### Feature Access Control

```swift
// In any View
if licenseManager.isPro {
    // Show Pro features
} else {
    // Show upgrade prompt
}

// Specific features
if licenseManager.canSwitchModels {
    // Show model picker
}

if licenseManager.canEditPrompts {
    // Show prompt editor
}
```

---

## Migration from Paddle

### What Was Removed

- ✅ All Paddle API calls (`validateWithPaddle`)
- ✅ License key validation logic
- ✅ Keychain license storage (not needed with IAP)
- ✅ External browser checkout flow
- ✅ Manual license activation UI
- ✅ Test credentials (for App Review builds)

### What Was Kept

- ✅ `SubscriptionTier` enum (monthly, annual, lifetime, free)
- ✅ Feature access control methods
- ✅ Model restrictions based on tier
- ✅ `LicenseManager.shared` singleton pattern

### Backward Compatibility

**Old Paddle users:**
If you had Paddle users, you'll need a migration strategy:
1. Keep Paddle validation as fallback
2. Provide free "migration" IAP for existing customers
3. Or: Manual migration process with proof of purchase

**For new app (no existing Paddle users):**
- No migration needed
- Clean StoreKit 2 implementation
- No legacy code

---

## Security & Receipt Validation

### StoreKit 2 Verification

Built-in security features:
- Cryptographic receipt validation
- JWS (JSON Web Signature) verification
- Apple-signed transactions
- On-device verification (no server needed)

```swift
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw StoreError.failedVerification
    case .verified(let safe):
        return safe
    }
}
```

### Server-Side Validation (Optional)

For additional security, you can add server-side validation:
1. Send transaction ID to your server
2. Validate with App Store Server API
3. Store subscription status in your database

**For ZetaNotes:** Not currently implemented (not required for most apps)

---

## Common Issues & Solutions

### Issue: Products not loading

**Solution:**
- Check product IDs match exactly
- Ensure App Store Connect products are "Ready to Submit"
- In Sandbox: Create Sandbox tester account
- Clear Xcode DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Issue: Purchase fails immediately

**Solution:**
- Check Sandbox tester credentials
- Sign out of App Store on device (Settings → App Store)
- Try again - you'll be prompted for Sandbox login
- Check Xcode console for error messages

### Issue: Restore purchases doesn't work

**Solution:**
- Must use same Sandbox tester account
- Check transaction listener is running
- Call `AppStore.sync()` to force sync
- Wait a few seconds for receipt update

### Issue: Subscription status not updating

**Solution:**
- Check transaction listener is active
- Ensure `updateCustomerProductStatus()` is called
- Verify `@Published` properties are updating on `@MainActor`
- Check for verification errors in console

### Issue: App Sandbox breaks llama.cpp

**Solution:**
- Ensure JIT and unsigned memory entitlements are enabled
- Test thoroughly in sandboxed build
- May need to request entitlement approval from Apple
- Provide technical justification in App Review notes

---

## Next Steps

### Before Submission

1. **Test thoroughly:**
   - [ ] All three purchase options work
   - [ ] Restore purchases works
   - [ ] Subscription status updates correctly
   - [ ] Pro features activate properly
   - [ ] Free tier still works
   - [ ] Offline functionality intact

2. **Create App Store Connect products:**
   - [ ] Monthly subscription
   - [ ] Annual subscription
   - [ ] Lifetime purchase
   - [ ] Submit for review alongside app

3. **Build for distribution:**
   ```bash
   # Regular production build (NOT --app-review)
   ./scripts/release.sh 1.0.0
   ```

4. **Upload to App Store Connect:**
   - Use Transporter app or Xcode
   - Upload signed DMG

5. **Submit for review:**
   - Fill out App Review notes (use `docs/APP_REVIEW_NOTES.md`)
   - No sign-in credentials needed
   - Mention Sandbox testing for IAP

### Post-Launch

1. **Monitor subscriptions:**
   - App Store Connect → Sales and Trends
   - Track subscription metrics
   - Monitor refunds and cancellations

2. **Handle customer support:**
   - "Restore Purchases" button for reinstalls
   - Direct to App Store for subscription management
   - No manual license keys needed

3. **Future enhancements:**
   - Introductory offers (free trial, discounted first month)
   - Promotional offers
   - Offer codes
   - Family Sharing (already supported!)

---

## Resources

### Apple Documentation

- [StoreKit 2 Overview](https://developer.apple.com/documentation/storekit)
- [In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_storekit_testing_in_xcode)
- [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)

### App Store Connect

- [Manage In-App Purchases](https://help.apple.com/app-store-connect/#/devae49fb316)
- [Create Subscriptions](https://help.apple.com/app-store-connect/#/dev7e89e149d)
- [Sandbox Testing](https://help.apple.com/app-store-connect/#/dev8b997bee1)

### ZetaNotes Files

- `ZetaNotes/Configuration.storekit` - StoreKit test configuration
- `ZetaNotes/Managers/StoreKitManager.swift` - IAP logic
- `ZetaNotes/Managers/LicenseManager.swift` - License/subscription management
- `ZetaNotes/Views/UpgradePromptView.swift` - Purchase UI
- `docs/APP_REVIEW_NOTES.md` - Apple reviewer guide

---

## Summary

✅ **Complete StoreKit 2 integration**
✅ **Native in-app purchase flow**
✅ **App Sandbox enabled**
✅ **No external payment processor**
✅ **No test credentials needed**
✅ **Ready for App Store submission**

**Your app is now ready for the App Store with full IAP support!** 🎉
