# NoteTaker Quick Start Guide

Get NoteTaker up and running in 5 minutes.

## Prerequisites Checklist

- [ ] macOS 13.0+ (Ventura or later)
- [ ] Xcode 15.0+
- [ ] Apple Silicon Mac (M1/M2/M3)
- [ ] ~5GB free disk space (for model + build artifacts)

## 5-Minute Setup

### Step 1: Open the Project (30 seconds)

```bash
cd /Users/projects/Documents/notetaker
open NoteTaker.xcodeproj
```

Wait for Xcode to open and index the project.

### Step 2: Build the App (1 minute)

In Xcode:

1. Select the **NoteTaker** scheme (top left)
2. Press **Cmd+B** to build
3. Wait for build to complete (should succeed)

### Step 3: Run Without AI (30 seconds)

1. Press **Cmd+R** to run the app
2. You should see an empty notes interface
3. Click "New Note" and start typing
4. Basic note-taking works, but AI features are mocked

**You now have a working note-taking app!**

### Step 4: One-Command Setup (3-5 minutes)

To enable real AI features with **automated setup**:

```bash
# Run the automated setup script
./scripts/setup-dev.sh
```

This script will:

- ✅ Check prerequisites (Xcode, CMake, Git)
- ✅ Clone and build llama.cpp with Metal support
- ✅ Create Swift-C++ bridging header
- ✅ Download TinyLlama model (~669MB)
- ✅ Verify everything is ready

**OR Manual Setup** (if you prefer):

```bash
# Download TinyLlama model (669MB)
curl -L -o tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf

# Create models directory
mkdir -p ~/Library/Application\ Support/NoteTaker/Models

# Move model
mv tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf ~/Library/Application\ Support/NoteTaker/Models/

# Clone and build llama.cpp
cd /Users/projects/Documents/notetaker
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake .. -DLLAMA_METAL=ON
cmake --build . --config Release
```

### Step 5: Configure Xcode Build Settings

After running the setup script, configure Xcode (one-time):

See [LLAMA_CPP_INTEGRATION.md](LLAMA_CPP_INTEGRATION.md) Step 2 for details.

**Quick version:**

1. Open `NoteTaker.xcodeproj`
2. Select NoteTaker target → Build Settings
3. Set:
   - **Bridging Header**: `$(SRCROOT)/NoteTaker/NoteTaker-Bridging-Header.h`
   - **Header Search Paths**: `$(SRCROOT)/llama.cpp` and `$(SRCROOT)/llama.cpp/common`
   - **Library Search Paths**: `$(SRCROOT)/llama.cpp/build/src`
   - **Other Linker Flags**: `-lllama -lc++`

## What Works Now?

### ✅ Without AI Integration (Mock Mode)

- ✅ Create, edit, delete notes
- ✅ Search notes by keyword
- ✅ Note list with previews
- ✅ Automatic timestamps
- ✅ Core Data persistence
- ⚠️ AI features return mock data

### ✅ With Full AI Integration

- ✅ Real-time autocomplete while typing
- ✅ Note summarization (one-click)
- ✅ Semantic search (find notes by meaning)
- ✅ Embedding generation
- ✅ <3GB memory usage
- ✅ Offline, local inference

## First Use Tutorial

### Create Your First Note

1. **Launch app**: Press Cmd+R in Xcode
2. **New note**: Click "New Note" or press Cmd+N
3. **Type content**: Start typing in the editor
4. **Auto-save**: Changes save automatically

### Try Search

1. **Type in search bar**: Top of sidebar
2. **See results**: Notes filtered in real-time
3. **Click result**: Opens note in editor

### Generate Summary (with AI)

1. **Write a long note**: At least 50 characters
2. **Click "Summarize"**: Sparkles button at bottom
3. **Wait 2-3 seconds**: Progress indicator shows
4. **See summary**: Appears in bottom toolbar

### Try Autocomplete (with AI)

1. **Type at least 10 characters**: In editor
2. **Pause typing for 500ms**: Wait for typing pause (new: reduces overhead)
3. **See suggestion**: Ghost text appears inline after cursor
4. **Accept**: Press **Tab**
5. **Dismiss**: Press **Esc** or just keep typing

### Index Notes for Semantic Search (with AI)

1. **Click "Index Notes"**: Toolbar button
2. **Wait**: Embeddings generate in background
3. **Search semantically**: Type concept, not keyword
4. **See results**: Ranked by relevance

## Common Commands

### Clean Build

```bash
xcodebuild -project NoteTaker.xcodeproj -scheme NoteTaker clean && xcodebuild -project NoteTaker.xcodeproj -scheme NoteTaker build && cd /Users/projects/Library/Developer/Xcode/DerivedData/NoteTaker-*/Build/Products/Debug && ./NoteTaker.app/Contents/MacOS/NoteTaker 2>&1

# Or just open the app (from anywhere)
open /Users/projects/Library/Developer/Xcode/DerivedData/NoteTaker-*/Build/Products/Debug/NoteTaker.app
```

**Tip**: Running from terminal shows debug output including:

- Model loading progress
- Metal GPU initialization
- Token generation logs
- Memory usage stats
- Error messages with stack traces

## Testing the Project

### Manual Tests

Test these features to verify everything works:

**Basic Functionality**:

- [ ] Create note (Cmd+N)
- [ ] Edit note content
- [ ] Auto-generate title from first line
- [ ] Delete note (right-click → Delete)
- [ ] Search by keyword

**UI/UX**:

- [ ] Three-column layout renders
- [ ] Sidebar shows note list
- [ ] Editor shows selected note
- [ ] Search bar filters notes
- [ ] Empty state shows when no notes

**AI Features** (requires llama.cpp):

- [ ] Model loads on launch (check toolbar indicator)
- [ ] Autocomplete appears after typing
- [ ] Summary generates on button click
- [ ] Semantic search finds relevant notes
- [ ] Memory stays under 3GB

### Performance Benchmarks

Expected performance on M1 Mac:

| Operation | Target | Actual |
|-----------|--------|--------|
| App launch | <2s | ? |
| Model load | <3s | ? |
| Create note | <100ms | ? |
| Autocomplete | <500ms | ? |
| Summarization | <3s | ? |
| Embedding | <300ms | ? |
| Search (1k notes) | <500ms | ? |

Run these and note your results!

## Troubleshooting

### App Won't Build

**Error**: Various build errors

**Solution**:

1. Clean build folder: Cmd+Shift+K
2. Restart Xcode
3. Check Xcode version (need 15.0+)
4. Verify macOS version (need 13.0+)

### Model Not Loading

**Error**: "Failed to load AI model: modelNotFound"

**Root Cause**: App sandboxing prevents access to files outside the app container.

**Solution**: See [TROUBLESHOOTING_AI_MODEL.md](TROUBLESHOOTING_AI_MODEL.md) for detailed fix.

**Quick Fix** (Development only):

1. Sandboxing has been disabled in `NoteTaker.entitlements`
2. Rebuild: `xcodebuild clean build`
3. Run from Xcode to see debug logs
4. Verify model exists:

   ```bash
   ls -lh ~/Library/Application\ Support/NoteTaker/Models/
   ```

5. Should see ~669MB `tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` file

### AI Features Don't Work

**Symptom**: Autocomplete/summary return placeholder text

**Reason**: llama.cpp not integrated (mock mode active)

**Solution**: Follow [LLAMA_CPP_INTEGRATION.md](LLAMA_CPP_INTEGRATION.md)

### High Memory Usage

**Symptom**: Activity Monitor shows >3GB

**Solution**:

1. Check model quantization (should be Q4, not FP16)
2. Reduce context size to 1024 in `LLMInferenceService.swift`
3. Click "Index Notes" only when needed
4. Restart app to clear caches

## Project Structure Overview

```text
NoteTaker/
├── NoteTaker.xcodeproj/        # Xcode project
├── NoteTaker/
│   ├── NoteTakerApp.swift      # App entry point
│   ├── Views/                  # SwiftUI UI layer
│   ├── ViewModels/             # Business logic
│   ├── Models/                 # Core Data schema
│   ├── AI/                     # AI services
│   ├── Storage/                # Persistence
│   └── Search/                 # Semantic search
├── README.md                   # Full documentation
├── ARCHITECTURE.md             # Technical deep-dive
├── LLAMA_CPP_INTEGRATION.md    # AI integration guide
└── QUICKSTART.md               # This file
```

## Next Steps

1. **Read [README.md](README.md)**: Full feature documentation
2. **Read [ARCHITECTURE.md](ARCHITECTURE.md)**: Understand the design
3. **Integrate AI**: Follow [LLAMA_CPP_INTEGRATION.md](LLAMA_CPP_INTEGRATION.md)
4. **Customize**: Add your own AI features
5. **Deploy**: Build for release and distribute

## Development Tips

### Xcode Shortcuts

- **Cmd+N**: New note (when app is running)
- **Cmd+B**: Build project
- **Cmd+R**: Run app
- **Cmd+.**: Stop app
- **Cmd+Shift+K**: Clean build folder
- **Cmd+F**: Find in file
- **Cmd+Shift+F**: Find in project

### Debugging

**View Console Output**:

1. Run app (Cmd+R)
2. Open Debug Area (Cmd+Shift+Y)
3. Watch for log messages (marked with emoji)

**Check Memory Usage**:

1. Open Activity Monitor
2. Filter for "NoteTaker"
3. Watch Memory column

**Profile Performance**:

1. Product → Profile (Cmd+I)
2. Choose Instruments template
3. Record and analyze

### Code Navigation

**Find by filename**:

- Press **Cmd+Shift+O**
- Type filename
- Press Enter

**Jump to definition**:

- Cmd+Click on symbol
- Or right-click → Jump to Definition

**Find references**:

- Right-click symbol
- Select "Find Call Hierarchy"

## Getting Help

- **Documentation**: Read [README.md](README.md)
- **Architecture**: Read [ARCHITECTURE.md](ARCHITECTURE.md)
- **AI Integration**: Read [LLAMA_CPP_INTEGRATION.md](LLAMA_CPP_INTEGRATION.md)
- **llama.cpp**: <https://github.com/ggerganov/llama.cpp>
- **TinyLlama**: <https://github.com/jzhang38/TinyLlama>

## Contributing

To extend NoteTaker:

1. **Add new AI service**: Create file in `AI/` folder
2. **Add to AIEngine**: Register in `AIEngine.swift`
3. **Add UI**: Create button/view in appropriate view
4. **Test**: Verify memory usage stays <3GB
5. **Document**: Update README with your feature

Example template: See "Adding New AI Features" section in [README.md](README.md).

---

**You're ready to build!** 🚀

Open NoteTaker.xcodeproj and press Cmd+R to start.
