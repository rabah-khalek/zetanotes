# Xcode Project Configuration Checklist

## ✅ Ensure All Files Are Properly Configured

### How to Verify Files Are Included

Run this script to check:
```bash
./scripts/verify-xcode-files.sh
```

**Note:** The script may show false positives because Xcode project files use UUIDs internally. If your app builds successfully, the files are properly included.

### Manual Verification in Xcode

1. **Open Xcode:**
   ```bash
   open ZetaNotes.xcodeproj
   ```

2. **Check Project Navigator:**
   - Press `Cmd+1` to show Project Navigator
   - Expand all folders
   - Look for any files shown in **red** (missing files)
   - Look for any files shown in **gray** (not in target)

3. **Check File Target Membership:**
   - Select any Swift file in Project Navigator
   - Press `Cmd+Option+1` to show File Inspector
   - Under "Target Membership", ensure "ZetaNotes" is checked

---

## 🛒 StoreKit Configuration Setup

### Current Status
- ✅ Configuration.storekit file exists
- ✅ File is added to Xcode project
- ⚠️  Scheme configuration may need update

### Fix "Loading Products..." Issue

#### Step 1: Enable StoreKit Testing in Xcode Scheme

1. **Open Xcode:**
   ```bash
   open ZetaNotes.xcodeproj
   ```

2. **Edit the Scheme:**
   - Menu: **Product → Scheme → Edit Scheme...**
   - Or press: `Cmd+<` (Command + Less-than)

3. **Configure StoreKit:**
   - Select **Run** in the left sidebar
   - Click the **Options** tab
   - Find "StoreKit Configuration" dropdown
   - Select: `Configuration.storekit`
   - Click **Close**

4. **Run the app:**
   - Press `Cmd+R`
   - Products should now load instantly!

#### Step 2: Verify It's Working

When you run the app and click "Upgrade to Pro":
- ✅ Should see: Monthly ($1), Annual ($6), Lifetime ($20)
- ❌ Should NOT see: "Loading products..." spinner

#### Alternative: Check Via Build Settings

If products still don't load:

1. In Xcode, select the **ZetaNotes** project (top of navigator)
2. Select the **ZetaNotes** target
3. Go to **Build Phases** tab
4. Expand **Copy Bundle Resources**
5. Verify `Configuration.storekit` is listed
6. If not, click `+` and add it

---

## 🔧 Common Issues & Solutions

### Issue: "Loading products..." forever

**Causes:**
1. StoreKit Configuration not selected in scheme
2. Product IDs in code don't match Configuration.storekit
3. StoreKit framework not linked

**Solution:**
```bash
# 1. Check product IDs match
grep "productID" ZetaNotes/Configuration.storekit
grep "case.*=.*com.zetanotes" ZetaNotes/Managers/StoreKitManager.swift

# They should match:
# - com.zetanotes.pro.monthly
# - com.zetanotes.pro.annual
# - com.zetanotes.pro.lifetime
```

### Issue: Build fails with missing files

**Solution:**
1. Clean build folder: `Cmd+Shift+K`
2. Clean derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/ZetaNotes-*
   ```
3. Rebuild: `Cmd+B`

### Issue: StoreKit configuration not appearing in scheme

**Solution:**
1. Make sure `Configuration.storekit` is in the project
2. File must be at: `ZetaNotes/Configuration.storekit`
3. Restart Xcode if needed

---

## 📋 Pre-Build Checklist

Before every build, verify:

- [ ] All Swift files compile without errors
- [ ] StoreKit Configuration is selected in scheme
- [ ] llama.cpp libraries are built (`llama.cpp/build/bin/`)
- [ ] No missing file references (red files in Project Navigator)
- [ ] Target membership is set for all source files

---

## 🚀 Quick Build Test

```bash
# Clean build
xcodebuild clean -project ZetaNotes.xcodeproj -scheme ZetaNotes

# Build
xcodebuild build -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Debug

# Check for errors
echo $?  # Should be 0 if successful
```

---

## 🛠️ Useful Xcode Commands

### Check Scheme Configuration
```bash
xcodebuild -project ZetaNotes.xcodeproj -scheme ZetaNotes -showBuildSettings | grep STOREKIT
```

### List All Schemes
```bash
xcodebuild -project ZetaNotes.xcodeproj -list
```

### Verify Target Membership
```bash
# Check if a file is in the target
grep -A 10 "StoreKitManager.swift" ZetaNotes.xcodeproj/project.pbxproj | grep PBXBuildFile
```

---

## 📝 Notes

- **StoreKit Testing** works WITHOUT App Store Connect setup
- **Configuration.storekit** provides local test products
- Products will load instantly if scheme is configured correctly
- You can test purchases without creating products in App Store Connect

---

## ✅ Final Verification

After configuring StoreKit in the scheme:

1. Run app in Xcode
2. Click "Upgrade to Pro"
3. Should immediately see:
   ```
   Monthly - $1/mo
   Annual - $6/yr
   Lifetime - $20 once
   ```
4. Click purchase → Should show StoreKit test dialog
5. Click "Subscribe" → Pro features unlock!

If you see this, everything is working! 🎉
