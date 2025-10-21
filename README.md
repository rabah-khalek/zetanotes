# ZetaNotes

**Privacy-first note-taking with offline AI for Mac**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)

ZetaNotes is a native macOS note-taking app that runs AI models completely offline on your device. No cloud, no tracking, no data collection. Everything stays on your Mac.

🔒 **100% Private** • ✨ **AI Autocomplete** • 📝 **Instant Summaries** • 🌍 **Translate to 12+ Languages** • 🔍 **Semantic Search**

---

## ✨ Features

### Free Tier (Forever)
- ✅ **AI Autocomplete** - Smart text completion powered by Llama 3.2 1B
- ✅ **Summarization** - Get quick summaries of long notes
- ✅ **Translation** - Translate to English, Spanish, French, German, Chinese, Japanese, Korean, and more
- ✅ **Semantic Search** - Find notes by meaning, not just keywords
- ✅ **Unlimited Notes** - No limits on note count or storage
- ✅ **100% Offline** - All AI processing happens locally
- ✅ **Privacy-First** - Zero telemetry, no cloud sync, no data collection

### Pro Tier (Optional - from $1/month)
- 🚀 **8 Open-Source AI Models** - Phi-3, Qwen 2.5, Llama 3.2, Gemma 2, SmolLM2 & more
- 💬 **AI Chat Assistant** - Natural conversations with AI
- 📥 **Download Any Model** - Switch between models anytime
- ✏️ **Custom Tools** - Create custom AI tools tailored to your workflow
- ⚙️ **Customize Everything** - Fine-tune prompts and parameters
- 💎 **Flexible Plans** - Monthly ($1), Annual ($6), or Lifetime ($20)

---

## 📦 Installation

### Requirements
- **macOS 13.0 (Ventura) or later**
- **Apple Silicon (M1/M2/M3/M4)** - optimized for Apple's chips, Intel supported
- **4 GB RAM** minimum (8 GB+ recommended)
- **1 GB disk space** (for app + AI model)

### Quick Install

1. **Download** the latest release from [GitHub Releases](https://github.com/rabah-khalek/zetanotes/releases)
2. **Open** the DMG file
3. **Drag** ZetaNotes.app to your Applications folder
4. **Double-click** to launch

That's it! ZetaNotes is **code signed** with an Apple Developer ID and **notarized** by Apple, so it installs like any professional Mac app - no security warnings!

### First Launch

On first launch, ZetaNotes will:
- Welcome you with a setup wizard
- Offer to download the AI model (optional, ~700MB)
- Guide you through the basic features

---

## 🚀 Getting Started

### Basic Usage

1. **Create a Note** - Click "+" or press `Cmd+N`
2. **Start Typing** - AI autocomplete activates automatically
3. **Accept Suggestions** - Press `Tab` to accept AI suggestions
4. **Search Notes** - Use semantic search to find by meaning
5. **AI Actions** - Select text and use toolbar buttons:
   - Summarize
   - Translate
   - Fix grammar/spelling
   - Reformulate (rewrite)

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+N` | New note |
| `Cmd+F` | Search notes |
| `Cmd+K` | Semantic search |
| `Tab` | Accept AI suggestion |
| `Esc` | Dismiss suggestion |
| `Cmd+,` | Settings |

---

## 🤖 AI Models

### Included (Free)
- **Llama 3.2 1B** - Meta's latest compact model with improved instruction-following
- Fast, lightweight, and perfect for everyday note-taking

### Pro Models (Optional)

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| **TinyLlama 1.1B** | 0.7 GB | Very Fast | Basic | Legacy option |
| **Qwen 2.5 1.5B** | 0.9 GB | Very Fast | Good | Balanced performance |
| **SmolLM2 1.7B** | 1.0 GB | Very Fast | Good | Instruction following |
| **Phi-2 2.7B** | 1.6 GB | Very Fast | Good+ | Reasoning |
| **Gemma 2 2B** | 1.4 GB | Very Fast | High | High quality |
| **Qwen 2.5 3B** | 2.0 GB | Fast | High | Complex tasks |
| **Llama 3.2 3B** | 2.0 GB | Fast | Very High | Multilingual |
| **Phi-3.5 Mini** | 2.3 GB | Fast | Very High | Best quality |

All models run with **Metal GPU acceleration** on Apple Silicon.

---

## 💻 Technical Details

### Architecture
- **UI**: SwiftUI (native macOS)
- **Database**: Core Data + SQLite
- **AI Engine**: llama.cpp with Metal GPU acceleration
- **Vector Search**: Local embeddings with cosine similarity
- **Model Format**: GGUF (quantized, optimized)

### Privacy & Security
- ✅ **No internet required** (except optional model downloads)
- ✅ **No analytics** or telemetry
- ✅ **No crash reporting** to external services
- ✅ **Local encryption** for license keys (macOS Keychain)
- ✅ **All data stays on your Mac**

### Performance
- 🚀 **Metal GPU acceleration** for AI inference
- 🚀 **Vector caching** (90% memory reduction)
- 🚀 **Optimized database** with Core Data indexes
- 🚀 **Batch operations** for fast bulk updates

### Storage Locations
- **Notes Database**: `~/Library/Application Support/ZetaNotes/notes.sqlite`
- **AI Models**: `~/Library/Application Support/ZetaNotes/Models/`
- **Settings**: `~/Library/Preferences/com.zetanotes.ZetaNotes.plist`

---

## 🛠️ Building from Source

### Prerequisites
- **Xcode 15.0+**
- **macOS 14.0+** (for development)
- **Swift 5.9+**

### Build Steps

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/zetanotes.git
cd zetanotes

# Initialize llama.cpp submodule
git submodule update --init --recursive

# Build llama.cpp libraries
cd llama.cpp
cmake -B build -DGGML_METAL=ON
cmake --build build --config Release
cd ..

# Open in Xcode
open ZetaNotes.xcodeproj

# Build and run
# Product → Run (Cmd+R)
```

### Project Structure

```
ZetaNotes/
├── AI/                    # AI engine & services
│   ├── AIEngine.swift
│   ├── LLMInferenceService.swift
│   ├── AutocompleteService.swift
│   └── SummarizationService.swift
├── Models/                # Core Data models
│   ├── Note.swift
│   └── NotesDataModel.xcdatamodeld
├── Views/                 # SwiftUI views
│   ├── ContentView.swift
│   ├── NoteListView.swift
│   ├── NoteEditorView.swift
│   └── AISettingsView.swift
├── Search/                # Semantic search engine
│   └── SemanticSearchEngine.swift
├── Managers/              # App managers
│   ├── LicenseManager.swift
│   └── ChatManager.swift
└── Storage/               # Data persistence
    └── PersistenceController.swift
```

---

## 🚀 Distribution (For Developers)

### Professional Distribution (Apple Developer Program)

ZetaNotes is **code signed** with an Apple Developer ID and **notarized** by Apple for professional, secure distribution.

**Build signed & notarized version:**
```bash
./scripts/release.sh 1.0.1
```

This creates a DMG with:

- ✅ **Code Signed** - App signed with Developer ID certificate
- ✅ **Notarized** - Verified safe by Apple's notarization service
- ✅ **No Security Warnings** - Users can double-click to install
- ✅ **Professional Experience** - Installs like any Mac app
- ✅ **Automatic Updates** - Seamless updates via Sparkle
- ✅ **Small Download** - ~80 MB (AI models downloaded on first run)

**User experience:**

- Install: Double-click DMG, drag to Applications, launch normally
- First run: Welcome wizard guides AI model download
- Updates: Automatic via Sparkle (no user action needed)
- Trust: App is verified by Apple

**Setup Requirements:**

1. Apple Developer Program membership ($99/year)
2. Developer ID Application certificate
3. App-Specific Password for notarization

See **[docs/APPLE_DEVELOPER_SETUP.md](docs/APPLE_DEVELOPER_SETUP.md)** for complete setup instructions.

**Benefits:**

- ✅ No security warnings or workarounds needed
- ✅ Professional presentation and user trust
- ✅ Seamless automatic updates
- ✅ Easy distribution via GitHub Releases
- ✅ Full App Store-quality user experience (without App Store requirements)

**CI/CD:** GitHub Actions automatically builds, signs, and notarizes releases when you push a version tag.

---

## 📝 License

MIT License - See [LICENSE](LICENSE) for details.

**You can:**
- ✅ Use commercially
- ✅ Modify
- ✅ Distribute
- ✅ Use privately

**You must:**
- Include copyright notice
- Include license text

---

## 🙏 Acknowledgments

Built with these amazing open-source projects:

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - Fast LLM inference in C/C++
- [TinyLlama](https://github.com/jzhang38/TinyLlama) - Compact 1.1B language model
- [Qwen2.5](https://github.com/QwenLM/Qwen2.5) - High-quality small models
- [Phi-3](https://huggingface.co/microsoft/phi-3-mini-128k-instruct) - Microsoft's reasoning model
- [Llama 3.2](https://ai.meta.com/llama/) - Meta's latest models

---

## 📞 Support & Contributing

### Get Help
- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/zetanotes/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/zetanotes/discussions)

### Contribute
Contributions welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Ways to help:**
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🌍 Translate the app
- 🔧 Submit pull requests

---

## 🎯 Roadmap

### v1.1 (Next)
- [ ] Export to Markdown/PDF
- [ ] Note linking and backlinks
- [ ] Tags and folders
- [ ] Dark mode improvements

### v1.2
- [ ] Voice notes with Whisper (local transcription)
- [ ] Image OCR
- [ ] Code syntax highlighting
- [ ] Custom themes

### Future
- [ ] iOS/iPadOS version
- [ ] End-to-end encrypted sync (optional)
- [ ] Plugin system

---

**Made with ❤️ for privacy-conscious note-takers**

*No cloud. No tracking. Just your notes and AI, working together on your Mac.*
