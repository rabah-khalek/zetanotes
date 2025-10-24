# Fix "Loading Products..." Issue

## The Problem
You're seeing a "Loading Products..." spinner because StoreKit Testing is not enabled in your Xcode scheme.

## The Solution (Takes 30 seconds)

### Step 1: Open Xcode Scheme Settings
1. Open `ZetaNotes.xcodeproj` in Xcode
2. Click the scheme selector at the top (shows "ZetaNotes")
3. Select **"Edit Scheme..."** (or press `Cmd+<`)

### Step 2: Enable StoreKit Configuration
1. In the left sidebar, select **"Run"**
2. Click the **"Options"** tab at the top
3. Find **"StoreKit Configuration"** section
4. From the dropdown, select **"Configuration.storekit"**
5. Click **"Close"**

### Step 3: Test
1. Run the app (`Cmd+R`)
2. Go to "Choose your plan"
3. Products should load **immediately** (no spinner)
4. You'll see:
   - Monthly: $1/month
   - Annual: $6/year
   - Lifetime: $20.00

## Visual Guide

```
┌─────────────────────────────────────┐
│ Edit Scheme: ZetaNotes              │
├─────────────────────────────────────┤
│ ┌─────────┐  ┌──────────────────┐  │
│ │ Build   │  │ Info  Options    │  │
│ │ Run   ◀ │  └──────────────────┘  │
│ │ Test    │                         │
│ │ Profile │  StoreKit Configuration │
│ │ Analyze │  ┌────────────────────┐ │
│ │ Archive │  │ Configuration.st ▼ │ │ ← Select this
│ └─────────┘  └────────────────────┘ │
└─────────────────────────────────────┘
```

## Verification

After configuring, you can verify it worked:

### Method 1: Run the app
- No "Loading Products..." spinner
- Prices show immediately

### Method 2: Check Xcode StoreKit Transactions
1. While app is running: `Debug` → `StoreKit` → `Manage Transactions`
2. You should see the StoreKit transaction manager
3. Products will be listed there

## Troubleshooting

### If Configuration.storekit is not in the dropdown:

1. **Verify file is in project:**
   ```bash
   ls -la ZetaNotes/Configuration.storekit
   ```
   Should show: `-rw-r--r--  1 user staff 3412 ...`

2. **Check project references:**
   ```bash
   grep -c "Configuration.storekit" ZetaNotes.xcodeproj/project.pbxproj
   ```
   Should show: `4` or higher

3. **If file exists but not showing:**
   - In Xcode Project Navigator, verify you can see `Configuration.storekit`
   - It should be in the `ZetaNotes` folder
   - If you can't see it, right-click `ZetaNotes` folder → "Add Files to ZetaNotes..."
   - Select `ZetaNotes/Configuration.storekit`

### If products still don't load:

1. **Clean build folder:** `Cmd+Shift+K`
2. **Reset Xcode package cache:** `File` → `Packages` → `Reset Package Caches`
3. **Restart Xcode completely**
4. **Check Console output** (`Cmd+Shift+Y`) for error messages

## What Happens Next

Once configured:
- ✅ Products load instantly
- ✅ You can test purchases in Simulator
- ✅ Purchases use StoreKit Testing (fake, safe purchases)
- ✅ You can view/clear test transactions in Xcode

## After Testing Locally

When you're ready for real Sandbox testing:
1. Create products in App Store Connect with matching IDs:
   - `com.zetanotes.pro.month`
   - `com.zetanotes.pro.annual`
   - `com.zetanotes.pro.lifetime`
2. Create Sandbox tester account
3. Test on real device

---

**Next:** Once products load, test the full purchase flow to ensure everything works!
