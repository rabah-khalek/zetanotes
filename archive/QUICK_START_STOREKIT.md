# Quick Start: StoreKit 2 Testing

## 🚀 Test in 30 Seconds

```bash
# 1. Open Xcode
open ZetaNotes.xcodeproj

# 2. Run (Cmd+R)
# 3. Click "Upgrade to Pro"
# 4. Select a tier → Click "Upgrade to Pro"
# 5. Click "Subscribe" in StoreKit dialog
# 6. ✅ Pro features unlocked!
```

---

## 📋 Quick Reference

### Product IDs

| Tier | Product ID | Price |
|------|------------|-------|
| Monthly | `com.zetanotes.pro.monthly` | $1/mo |
| Annual | `com.zetanotes.pro.annual` | $6/yr |
| Lifetime | `com.zetanotes.pro.lifetime` | $20 once |

### Key Files

| File | Purpose |
|------|---------|
| `Configuration.storekit` | StoreKit test config |
| `StoreKitManager.swift` | IAP logic |
| `LicenseManager.swift` | Feature access control |
| `UpgradePromptView.swift` | Purchase UI |

---

## ✅ Testing Checklist

Quick tests before submission:

- [ ] Purchase monthly → Pro activates
- [ ] Purchase annual → Pro activates
- [ ] Purchase lifetime → Pro activates
- [ ] Quit app → Relaunch → Still Pro
- [ ] "Restore Purchases" works
- [ ] Free tier works (no purchase)

---

## 🎯 App Store Connect Setup

1. **Go to:** [App Store Connect](https://appstoreconnect.apple.com)
2. **Create:** 3 IAP products (monthly, annual, lifetime)
3. **Match:** Product IDs exactly as shown above
4. **Submit:** Products with your app

---

## 📝 For Apple Reviewers

**No sign-in needed!**

Apple will test using Sandbox:
- Create test purchase in Sandbox
- Pro features activate automatically
- Use "Restore Purchases" to restore

See `docs/APP_REVIEW_NOTES.md` for full details.

---

## 🛠️ Troubleshooting

**Products not loading?**
- Product IDs must match exactly
- App Store Connect products must be "Ready to Submit"

**Purchase fails?**
- In Xcode testing: Works automatically
- On device: Need Sandbox tester account

**Still see Paddle?**
- Old code backed up as `*_Paddle_Backup.swift`
- New code is active

---

## 📚 Full Documentation

- `STOREKIT_MIGRATION_SUMMARY.md` - What changed
- `docs/STOREKIT_IMPLEMENTATION.md` - Complete guide
- `docs/APP_REVIEW_NOTES.md` - Apple reviewer info

---

**Ready to submit!** 🎉
