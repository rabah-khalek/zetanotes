# Data Separation in OffNotes

Understanding how user data is stored and why your dev data won't ship with the app.

---

## 📁 Where Data Lives

### App Bundle (Shipped with App)
**Location:** `/Applications/OffNotes.app/Contents/Resources/`

**What's here:**
- ✅ App code (Swift binaries)
- ✅ UI resources (icons, images)
- ✅ TinyLlama model (bundled, ~700MB)
- ❌ **NO user data** (notes, settings, etc.)

**This is READ-ONLY after installation.**

### User Data Directory (Per-User, Not Shipped)
**Location:** `~/Library/Application Support/NoteTaker/`

**What's here:**
- ✅ User's notes database (`notes.sqlite`)
- ✅ Downloaded AI models (Pro models)
- ✅ User preferences
- ✅ Logs

**This is unique to each user.**

### User Preferences (Per-User, Not Shipped)
**Location:** `~/Library/Preferences/com.notetaker.NoteTaker.plist`

**What's here:**
- ✅ Selected AI model
- ✅ App settings
- ✅ Window positions
- ✅ License info (in Keychain)

**This is unique to each user.**

---

## 🔒 Why Your Dev Data Won't Ship

### How macOS Apps Work:

1. **App Bundle** = The .app file in Applications
   - Contains only the app code and bundled resources
   - Same for all users
   - Read-only

2. **User Data** = Separate per-user folders
   - Each macOS user has their own
   - Located in `~/Library/` (user's home folder)
   - Never included in the .app bundle

### What Happens:

**When you develop:**
- Your notes go to: `/Users/YOUR_USERNAME/Library/Application Support/NoteTaker/`
- Your model preference goes to: `/Users/YOUR_USERNAME/Library/Preferences/`

**When you build a release:**
- Script copies: `/Applications/OffNotes.app/` (just the code)
- Script does NOT copy: `~/Library/Application Support/NoteTaker/` (your data)

**When a user installs:**
- They get: Clean OffNotes.app (no data)
- They create: Fresh `~/Library/Application Support/NoteTaker/` folder
- They start with: Empty database, default settings

---

## ✅ Build Script Safeguards

Both scripts include cleanup steps:

```bash
# Remove any development databases from app bundle
rm -rf "$BUILD_DIR/OffNotes.app/Contents/Resources/"*.sqlite*
rm -rf "$BUILD_DIR/OffNotes.app/Contents/Resources/"*.db
```

This is a **safety precaution** in case you accidentally:
- Moved your database into Resources folder
- Bundled test data
- Included development files

**In practice:** This usually finds nothing to delete, because Core Data stores data in `~/Library/Application Support/` by default.

---

## 🎯 Default Settings for New Users

### Model Selection
- **Default:** TinyLlama 1.1B (line 56 in AIEngine.swift)
- **Bundled:** Yes, included in .app
- **Active:** Automatically selected on first launch
- **Location:** `/Applications/OffNotes.app/Contents/Resources/Models/`

### Notes Database
- **Default:** Empty (no notes)
- **Created:** On first launch
- **Location:** `~/Library/Application Support/NoteTaker/notes.sqlite`

### Settings
- **Default:** All features enabled (free tier)
- **Location:** `~/Library/Preferences/`

---

## 🔍 Verify Clean Build

After building, check what's in the app bundle:

```bash
# List all files in Resources
ls -la ~/Desktop/OffNotes-Release-*/OffNotes.app/Contents/Resources/

# Should see:
# - Models/ folder (with TinyLlama)
# - AppIcon.icns
# - Assets.car
# - Info.plist
#
# Should NOT see:
# - *.sqlite files
# - *.db files
# - notes/ folder
```

---

## 🧪 Test Clean Install

### Method 1: Create Test User

```bash
# 1. Create new macOS user account
# System Settings → Users & Groups → Add User

# 2. Log in as test user

# 3. Install OffNotes

# 4. Launch - should be completely clean:
#    - No notes
#    - TinyLlama selected by default
#    - Default settings
```

### Method 2: Clean User Library

```bash
# 1. Backup your data
cp -R ~/Library/Application\ Support/NoteTaker ~/Desktop/NoteTaker-backup

# 2. Remove app data
rm -rf ~/Library/Application\ Support/NoteTaker
rm ~/Library/Preferences/com.notetaker.NoteTaker.plist

# 3. Launch app - fresh install simulation

# 4. Restore your data
rm -rf ~/Library/Application\ Support/NoteTaker
mv ~/Desktop/NoteTaker-backup ~/Library/Application\ Support/NoteTaker
```

---

## 📊 Data Location Summary

| Data Type | Location | Shipped? | Default for New Users |
|-----------|----------|----------|----------------------|
| **App Code** | `/Applications/OffNotes.app/` | ✅ Yes | Same for everyone |
| **TinyLlama Model** | `.../Resources/Models/` | ✅ Yes | Bundled, active |
| **User Notes** | `~/Library/Application Support/NoteTaker/` | ❌ No | Empty database |
| **Settings** | `~/Library/Preferences/` | ❌ No | Default values |
| **License** | Keychain | ❌ No | Free tier |
| **Pro Models** | `~/Library/Application Support/NoteTaker/Models/` | ❌ No | Not downloaded |

---

## 🚨 Common Mistakes (Now Fixed)

### ❌ Wrong: Storing Data in App Bundle
```swift
// DON'T DO THIS
let dataPath = Bundle.main.resourcePath + "/data.sqlite"
```

**Problem:** App bundle is read-only after installation

### ✅ Correct: Using Application Support
```swift
// PersistenceController.swift already does this correctly:
let appSupport = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
).first!
let storeURL = appSupport
    .appendingPathComponent("NoteTaker")
    .appendingPathComponent("notes.sqlite")
```

**Result:** Each user gets their own data folder

---

## 🎉 Summary

**You're safe!** Your development data will NOT ship with the app because:

1. ✅ **macOS separates app code from user data**
   - App bundle: `/Applications/` (shipped)
   - User data: `~/Library/` (NOT shipped)

2. ✅ **Your code stores data correctly**
   - Uses `ApplicationSupportDirectory`
   - Not in app bundle

3. ✅ **Build script includes cleanup**
   - Removes any accidental database files
   - Extra safety layer

4. ✅ **TinyLlama is bundled and default**
   - Included in app bundle
   - Set as default model
   - Users start with it active

**New users get:**
- ✅ Clean, empty app
- ✅ TinyLlama model ready to use
- ✅ Default settings
- ✅ No notes
- ✅ Professional experience

**You keep:**
- ✅ All your development notes
- ✅ Your settings
- ✅ Your downloaded models
- ✅ Everything in `~/Library/Application Support/NoteTaker/`

---

## 🔧 If You Want to Reset (Development)

```bash
# Nuclear option - completely reset app data
rm -rf ~/Library/Application\ Support/NoteTaker
rm ~/Library/Preferences/com.notetaker.NoteTaker.plist

# Restart app - fresh install!
```

This simulates what a new user experiences.
