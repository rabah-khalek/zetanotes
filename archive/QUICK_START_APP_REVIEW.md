# Quick Start: App Review Submission

## 🚀 TL;DR - What You Need to Know

You're submitting ZetaNotes to Apple for review **before** implementing In-App Purchases. This requires special test credentials.

## ⚡ Quick Steps

### 1. Build for App Review

```bash
./scripts/release.sh 1.0.0 --app-review
```

**Important:** Use the `--app-review` flag!

### 2. Submit to App Store Connect

Upload the generated DMG to App Store Connect.

### 3. Fill Out Sign-In Information

In App Store Connect → App Review Information:

**Username:** `admin`
**Password:** `TEST`

### 4. Add Notes

Copy this into the "Notes" field:

```
This is a special App Review build with test credentials enabled.

Test Credentials:
- Email: admin
- License Key: TEST

These credentials grant Lifetime Pro access to test all features.

Note: We are migrating from Paddle to Apple In-App Purchases.
IAP integration will be completed in an upcoming update.
```

### 5. Submit for Review

Click "Submit for Review" ✅

---

## 📋 Test Credentials

| Field | Value |
|-------|-------|
| Email | `admin` |
| License Key | `TEST` |
| Access Level | Lifetime Pro |

## 🎯 How Reviewers Use Credentials

1. Launch ZetaNotes
2. Click "Settings" → "License"
3. Click "Activate License"
4. Enter: Email=`admin`, Key=`TEST`
5. Click "Activate"
6. ✅ All Pro features unlocked

## ⚠️ Important Notes

- **App Review builds ONLY** - Never use `--app-review` for public releases
- Test credentials only work in builds created with `--app-review` flag
- Production builds (without flag) will NOT accept these credentials
- This is temporary until IAP is implemented

## 📚 Detailed Documentation

- [APP_REVIEW_BUILD.md](scripts/APP_REVIEW_BUILD.md) - Developer guide
- [APP_REVIEW_NOTES.md](docs/APP_REVIEW_NOTES.md) - Full review notes
- [APP_REVIEW_IMPLEMENTATION.md](scripts/APP_REVIEW_IMPLEMENTATION.md) - Technical details

## ✅ Verification Checklist

Before submitting:

- [ ] Built with `./scripts/release.sh X.X.X --app-review`
- [ ] Console showed "APP REVIEW MODE ENABLED"
- [ ] Tested credentials work (admin/TEST)
- [ ] Pro features accessible after activation
- [ ] Filled out App Store Connect sign-in info
- [ ] Added notes explaining test credentials
- [ ] DMG uploaded to App Store Connect

## 🔄 After IAP Implementation

Once In-App Purchases are ready:

1. Remove `--app-review` flag from build command
2. Use Sandbox testers for IAP testing
3. Update App Store Connect notes
4. Submit new version

## 🆘 Troubleshooting

**Test credentials don't work:**
- Did you use `--app-review` flag?
- Check console output for "APP REVIEW MODE"

**Build fails:**
- Verify syntax: `bash -n scripts/release.sh`
- Check Xcode version (requires 12+)

**Not sure if App Review mode is enabled:**
```bash
# Check the build logs
grep -r "APP REVIEW" releases/
```

---

**Ready to submit?** Run the build command and follow the steps above! 🎉
