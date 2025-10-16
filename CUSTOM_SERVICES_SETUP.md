# Custom Services Setup Guide

## 🔴 Build Error Fix

The build is failing because the new Swift files need to be added to your Xcode project.

## ✅ Quick Fix: Add Files to Xcode

### Method 1: Using Xcode (Recommended)

1. **Open Xcode** and your NoteTaker project

2. **Add CustomService.swift:**
   - In Xcode's Project Navigator (left sidebar), right-click on the **Models** folder
   - Select **"Add Files to NoteTaker..."**
   - Navigate to: `NoteTaker/Models/CustomService.swift`
   - **IMPORTANT:** Uncheck "Copy items if needed" (file is already in correct location)
   - **IMPORTANT:** Check "NoteTaker" under "Add to targets"
   - Click **"Add"**

3. **Add AISettingsViewRedesigned.swift:**
   - Right-click on the **Views** folder in Xcode
   - Select **"Add Files to NoteTaker..."**
   - Navigate to: `NoteTaker/Views/AISettingsViewRedesigned.swift`
   - **IMPORTANT:** Uncheck "Copy items if needed"
   - **IMPORTANT:** Check "NoteTaker" under "Add to targets"
   - Click **"Add"**

4. **Add CustomServiceEditorView.swift:**
   - Right-click on the **Views** folder in Xcode
   - Select **"Add Files to NoteTaker..."**
   - Navigate to: `NoteTaker/Views/CustomServiceEditorView.swift`
   - **IMPORTANT:** Uncheck "Copy items if needed"
   - **IMPORTANT:** Check "NoteTaker" under "Add to targets"
   - Click **"Add"**

5. **Build the project** (⌘B)

---

### Method 2: Drag and Drop

1. Open **Finder** and navigate to: `/Users/projects/Documents/notetaker/NoteTaker/`

2. Open **Xcode** with your NoteTaker project

3. **Drag these files** from Finder into Xcode:
   - `Models/CustomService.swift` → drag into the Models folder in Xcode
   - `Views/AISettingsViewRedesigned.swift` → drag into the Views folder in Xcode
   - `Views/CustomServiceEditorView.swift` → drag into the Views folder in Xcode

4. When the dialog appears:
   - **Uncheck** "Copy items if needed"
   - **Check** "NoteTaker" under "Add to targets"
   - Click **"Finish"**

5. **Build the project** (⌘B)

---

## 📦 Files to Add

The following files have been created and need to be added to Xcode:

1. ✅ **CustomService.swift** (in `NoteTaker/Models/`)
   - Model for custom AI services
   - `CustomService` struct
   - `ServiceColor` enum
   - `CustomServiceManager` class

2. ✅ **AISettingsViewRedesigned.swift** (in `NoteTaker/Views/`)
   - Redesigned settings view with sidebar navigation
   - Three sections: General, Prompts, Custom Services

3. ✅ **CustomServiceEditorView.swift** (in `NoteTaker/Views/`)
   - Editor dialog for creating/editing custom services
   - Validation and live preview

---

## 🔧 Modified Files

These files have been updated and should build correctly once the new files are added:

1. **ContentView.swift** - Integrated custom services in toolbar
2. **NoteViewModel.swift** - Added custom service execution logic
3. **AnalyticsManager.swift** - Fixed missing sessionId parameter

---

## 🎯 After Adding Files

Once you've added the files to Xcode:

1. **Clean Build Folder** (⌘⇧K)
2. **Build** (⌘B)
3. **Run** (⌘R)

You should now see:
- ✅ Redesigned settings window with sidebar
- ✅ Custom Services section (locked for non-PRO users)
- ✅ Ability to create custom AI services (PRO only)
- ✅ Custom services appear in toolbar with keyboard shortcuts

---

## 🐛 Troubleshooting

### If build still fails:

1. **Check File Membership:**
   - Select each new file in Xcode
   - Open the File Inspector (⌥⌘1)
   - Under "Target Membership", ensure **NoteTaker** is checked

2. **Check File Paths:**
   - Files should be in:
     - `NoteTaker/Models/CustomService.swift`
     - `NoteTaker/Views/AISettingsViewRedesigned.swift`
     - `NoteTaker/Views/CustomServiceEditorView.swift`

3. **Clean Derived Data:**
   - Xcode menu → Product → Clean Build Folder (⌘⇧K)
   - Close Xcode
   - Delete `~/Library/Developer/Xcode/DerivedData/NoteTaker-*`
   - Reopen Xcode and build

---

## 📝 Verification

After successful build, test the features:

1. Open the app
2. Click the **Settings (⚙️)** button
3. You should see:
   - Sidebar with 3 sections: General, Prompts, Custom Services
   - Navigate to **Custom Services**
   - If PRO: Click **"+ Add Service"** to create a custom service
   - If not PRO: See locked button with upgrade prompt

---

## 💡 Quick Test

Create a test custom service:
- Name: "Test Service"
- Icon: Star
- Color: Purple
- Shortcut: K
- Prompt: "Make this text more engaging and fun to read."

After saving, you should see the service in your toolbar with ⌘K shortcut!
