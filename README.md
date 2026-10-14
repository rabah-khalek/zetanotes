# ZetaNotes

> **Status: free, final release, no longer maintained.**
> Version 1.0.3 removed in-app purchases; every former Pro feature is unlocked for everyone.
> Download the notarized build from [GitHub Releases](https://github.com/rabah-khalek/zetanotes/releases/latest).
> The Mac App Store listing is available until late October 2026, and installed copies keep working after that.
> The source is MIT licensed, so anyone can build or fork it. Website: https://www.zetanotes.com

Offline AI notes for Mac. ZetaNotes runs small open-source language models locally through
[llama.cpp](https://github.com/ggerganov/llama.cpp): autocomplete, summarization, translation,
grammar fixes, rephrasing, semantic search, custom tools and a chat interface, with no internet
connection and no account. Notes stay on your Mac.

## Download

- Notarized DMG: https://github.com/rabah-khalek/zetanotes/releases/latest
- Mac App Store (until late October 2026): https://apps.apple.com/app/id6754346516

Requires macOS 13 or later; Apple silicon recommended. AI models are downloaded on first use from Hugging Face.

## Building from source

1. Clone this repository.
2. Clone llama.cpp into the repository root. The Xcode build phase expects it at `llama.cpp/` and
   compiles it automatically (the final release used llama.cpp tag b6823):

   ```bash
   git clone --depth 1 https://github.com/ggerganov/llama.cpp.git
   ```

   `scripts/setup-dev.sh` does the same and prebuilds it.
3. Open `ZetaNotes.xcodeproj` in Xcode 16 or later and build the `ZetaNotes` scheme.

The signing, notarization and DMG scripts in `scripts/` need an Apple Developer membership and are
kept for reference; see `scripts/RELEASE_WORKFLOW.md`.

## Project layout

- `ZetaNotes/` app sources (SwiftUI)
- `docs/` website, served by GitHub Pages
- `scripts/` build and release tooling
- `archive/` historical development notes

## License

MIT. See [LICENSE](LICENSE).
