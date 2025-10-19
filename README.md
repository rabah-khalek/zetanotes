# ZetaNotes

**Privacy-first note-taking with offline AI for Mac**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)

ZetaNotes is a native macOS note-taking app that runs AI models completely offline on your device. No cloud, no tracking, no data collection. Everything stays on your Mac.

🔒 **100% Private** • ✨ **AI Autocomplete** • 📝 **Instant Summaries** • 🌍 **Translate to 12+ Languages** • 🔍 **Semantic Search**

**[Download Latest Release](https://github.com/YOUR_USERNAME/zetanotes/releases/latest)** | **[Documentation](https://YOUR_USERNAME.github.io/zetanotes/)** | **[Upgrade to Pro (from $1/month)](https://zetanotes.lemonsqueezy.com/checkout)**

---

## ✨ Features

### Free Tier (Forever)
- ✅ **AI Autocomplete** - Smart text completion powered by TinyLlama 1.1B
- ✅ **Summarization** - Get quick summaries of long notes
- ✅ **Translation** - Translate to English, Spanish, French, German, Chinese, Japanese, Korean, and more
- ✅ **Semantic Search** - Find notes by meaning, not just keywords
- ✅ **Unlimited Notes** - No limits on note count or storage
- ✅ **100% Offline** - All AI processing happens locally
- ✅ **Privacy-First** - Zero telemetry, no cloud sync, no data collection

### Pro Tier (starting at $1/month)
- 🚀 **8 Open-Source AI Models** - Phi-3, Qwen 2.5, Llama 3.2, Gemma 2, SmolLM2 & more
- 💬 **AI Chat Assistant** - Natural conversations with AI using selected model
- 📥 **Download Any Model** - Switch between models anytime
- ✏️ **Custom Tools** - Create custom AI tools tailored to your workflow
- ⚙️ **Customize Everything** - Fine-tune prompts, chat parameters, and more
- ⚡ **Better Quality** - Larger models = smarter, more accurate results
- 🎁 **Future Updates** - New models and features added regularly
- 💎 **Flexible Plans** - Monthly ($1), Annual ($10), or Lifetime ($30)

---

## 🎯 Why ZetaNotes?

| Feature | ZetaNotes | Cloud-Based Apps |
|---------|----------|------------------|
| **Privacy** | 100% offline | ❌ Data sent to servers |
| **AI Features** | ✅ Local models | ⚠️ Requires internet |
| **Speed** | ⚡ Instant | 🐌 Network latency |
| **Cost** | $0-$30 one-time or $1-10/month | 💸 $10-20/month |
| **Data Security** | 🔒 Never leaves your Mac | ⚠️ Stored in cloud |
| **Works Offline** | ✅ Always | ❌ Internet required |

---

## 📦 Installation

### Requirements
- **macOS 13.0** (Ventura) or later
- **Apple Silicon** (M1/M2/M3/M4) recommended
- **4 GB RAM** minimum (8 GB+ recommended)
- **1 GB disk space** (+ more for open-source models)

### Download

1. Download the latest DMG from [Releases](https://github.com/YOUR_USERNAME/zetanotes/releases/latest)
2. Open `ZetaNotes.dmg`
3. Drag **ZetaNotes** to Applications folder
4. Open ZetaNotes from Applications

### First Launch

On first launch, macOS may show a security warning. To open:
1. Right-click ZetaNotes in Applications
2. Select "Open" from the menu
3. Click "Open" in the dialog

Or: System Settings → Privacy & Security → "Open Anyway"

**Full installation guide:** [docs/download.html](https://YOUR_USERNAME.github.io/zetanotes/download.html)

---

## 🚀 Getting Started

### Basic Usage

1. **Create a Note** - Click "+" or press `Cmd+N`
2. **Start Typing** - AI autocomplete activates automatically
3. **Accept Suggestions** - Press `Tab` to accept AI suggestions
4. **Search Notes** - Use semantic search to find by meaning
5. **AI Actions** - Right-click selected text for:
   - Summarize
   - Translate
   - Patch (grammar/spelling fix)
   - Reformulate (rewrite)

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+N` | New note |
| `Cmd+F` | Search notes |
| `Cmd+,` | Settings |
| `Tab` | Accept AI suggestion |
| `Esc` | Dismiss suggestion |
| `Cmd+K` | Semantic search |

---

## 🤖 AI Models

### Included (Free)
- **TinyLlama 1.1B** - Lightweight, fast, perfect for autocomplete and embeddings

### Pro Models (from $1/month)

**Choose your plan:**
- **Monthly**: $1/month - Perfect for trying out Pro features
- **Annual**: $10/year - Best value, save $2 per year
- **Lifetime**: $30 one-time - Pay once, own forever

**All plans include access to:**

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| **Llama 3.2 1B** | 0.7 GB | Very Fast | Basic+ | Quick tasks |
| **Qwen 2.5 1.5B** | 0.9 GB | Very Fast | Good | Balanced performance |
| **SmolLM2 1.7B** | 1.0 GB | Very Fast | Good | Instruction following |
| **Phi-2 2.7B** | 1.6 GB | Very Fast | Good+ | Reasoning tasks |
| **Gemma 2 2B** | 1.4 GB | Very Fast | High | High quality |
| **Qwen 2.5 3B** | 2.0 GB | Fast | High | Complex tasks |
| **Llama 3.2 3B** | 2.0 GB | Fast | Very High | Multilingual |
| **Phi-3.5 Mini** | 2.3 GB | Fast | Very High | Best quality |

All models run with **Metal GPU acceleration** on Apple Silicon for maximum performance.

---

## ⚙️ Configuration

### AI Settings

1. Open **Settings** → **AI Settings**
2. **Change Model** (Pro only):
   - Click "Download" next to any open-source model
   - After download, click "Use This"
3. **Customize Prompts** (Pro only):
   - Edit prompts for autocomplete, summarization, translation, etc.
   - Reset to defaults anytime

### Storage Location

- **Notes Database**: `~/Library/Application Support/ZetaNotes/notes.sqlite`
- **Downloaded Models**: `~/Library/Application Support/ZetaNotes/Models/`
- **Logs**: `~/Library/Logs/ZetaNotes/`

---

## 💻 Technical Details

### Architecture

- **UI Framework**: SwiftUI
- **Database**: Core Data with SQLite
- **AI Engine**: llama.cpp with Metal GPU acceleration
- **Vector Search**: Local embeddings with cosine similarity
- **Model Format**: GGUF (quantized, optimized for inference)

### Privacy & Security

- ✅ **No Network Requests** (except for optional model downloads)
- ✅ **No Analytics** or telemetry
- ✅ **No Crash Reporting** to external services
- ✅ **Local Encryption** using macOS Keychain for license keys
- ✅ **File Permissions** set to owner-only (0600)

### Performance Optimizations

- 🚀 **N+1 Query Prevention** via relationship prefetching
- 🚀 **Vector Caching** with NSCache (90% memory reduction)
- 🚀 **Search Result Caching** (5-minute TTL)
- 🚀 **Core Data Indexes** on frequently queried fields
- 🚀 **Batch Operations** for bulk updates
- 🚀 **Metal GPU Acceleration** for inference

---

## 🛠️ Development

### Build Requirements

- **Xcode 15.0+**
- **macOS 14.0+** (for development)
- **Swift 5.9+**

### Building from Source

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/zetanotes.git
cd zetanotes

# Initialize llama.cpp submodule
git submodule update --init --recursive

# Build llama.cpp
cd llama.cpp
cmake -B build -DGGML_METAL=ON
cmake --build build --config Release

# Open in Xcode
cd ..
open ZetaNotes.xcodeproj

# Run in Xcode
# Product → Run (Cmd+R)
```

### Project Structure

```
ZetaNotes/
├── AI/                    # AI engine & inference
│   ├── AIEngine.swift
│   ├── LLMInferenceService.swift
│   └── AutocompleteService.swift
├── Models/                # Core Data models
│   ├── Note.swift
│   └── NotesDataModel.xcdatamodeld
├── Views/                 # SwiftUI views
│   ├── ContentView.swift
│   ├── AISettingsView.swift
│   └── UpgradePromptView.swift
├── Search/                # Semantic search
│   └── SemanticSearchEngine.swift
├── Managers/              # Licensing, analytics
│   ├── LicenseManager.swift
│   └── AnalyticsManager.swift
└── Utilities/             # Helpers
    ├── Logger.swift
    └── SystemMonitor.swift
```

### Running Tests

```bash
# Unit tests
xcodebuild test -scheme ZetaNotes -destination 'platform=macOS'

# Or in Xcode
# Product → Test (Cmd+U)
```

---

## 📈 Roadmap

### v1.1 (Next Release)
- [ ] iCloud sync (optional, end-to-end encrypted)
- [ ] Export notes to Markdown/PDF
- [ ] Note linking and backlinks
- [ ] Tags and folders

### v1.2
- [ ] Voice notes with Whisper (local transcription)
- [ ] Image OCR
- [ ] Code syntax highlighting
- [ ] Plugin system

### v2.0
- [ ] iOS/iPadOS version
- [ ] Collaborative editing
- [ ] Advanced search filters
- [ ] Custom themes

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Ways to Contribute

- 🐛 **Report bugs** via [GitHub Issues](https://github.com/YOUR_USERNAME/zetanotes/issues)
- 💡 **Suggest features** in Discussions
- 📝 **Improve documentation**
- 🔧 **Submit pull requests**
- 🌍 **Translate the app** to other languages

### Development Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

ZetaNotes is open source under the MIT License. See [LICENSE](LICENSE) for details.

**TL;DR:** You can use, modify, and distribute this software freely, including for commercial purposes.

---

## 🙏 Acknowledgments

ZetaNotes is built with these amazing open-source projects:

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - LLM inference in C/C++
- [TinyLlama](https://github.com/jzhang38/TinyLlama) - Compact 1.1B parameter model
- [Qwen2.5](https://github.com/QwenLM/Qwen2.5) - High-quality small models
- [Phi-3](https://huggingface.co/microsoft/phi-3-mini-128k-instruct) - Microsoft's reasoning model
- [Llama 3.2](https://ai.meta.com/llama/) - Meta's latest small models

---

## 📞 Support

- **Website**: https://YOUR_USERNAME.github.io/zetanotes/
- **Email**: support@zetanotes.app
- **GitHub Issues**: https://github.com/YOUR_USERNAME/zetanotes/issues

---

## ⭐ Star History

If you find ZetaNotes useful, please consider starring the repository!

[![Star History Chart](https://api.star-history.com/svg?repos=YOUR_USERNAME/zetanotes&type=Date)](https://star-history.com/#YOUR_USERNAME/zetanotes&Date)

---

**Made with ❤️ for privacy-conscious note-takers**

[Download](https://YOUR_USERNAME.github.io/zetanotes/) • [Website](https://YOUR_USERNAME.github.io/zetanotes/) • [Upgrade to Pro](https://zetanotes.lemonsqueezy.com/checkout)
