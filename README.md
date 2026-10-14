# ZetaNotes

> **Status: free, final release, no longer maintained.**
> Version 1.0.3 removed in-app purchases; every former Pro feature is unlocked for everyone.
> Download the notarized build from [GitHub Releases](https://github.com/rabah-khalek/zetanotes/releases/latest).
> The Mac App Store listing is available until late October 2026, and installed copies keep working after that.
> The source is MIT licensed, so anyone can build or fork it. Website: https://rabah-khalek.github.io/zetanotes/

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

   `scripts/setup-dev.sh` does the same and prebuilds it, or run `make llama`.
3. Open `ZetaNotes.xcodeproj` in Xcode 16 or later and build the `ZetaNotes` scheme, or run `make build`.

`make format` and `make lint` run SwiftFormat and SwiftLint with the configuration in `.swiftformat`
and `.swiftlint.yml`. The signing, notarization and DMG scripts need an Apple Developer membership
and are documented in [scripts/README.md](scripts/README.md).

## Project layout

- `ZetaNotes/` app sources (SwiftUI): `AI/`, `Managers/`, `Models/`, `Search/`, `Storage/`, `Utilities/`, `ViewModels/`, `Views/`
- `ZetaNotes.xcodeproj/` Xcode project; Swift package dependencies are resolved by Xcode
- `web/` website, published to rabah-khalek.github.io/zetanotes by the Pages workflow in `.github/workflows/`
- `scripts/` build and release tooling, see `scripts/README.md`
- `Makefile` shortcuts for the scripts above
- `CHANGELOG.md` release history

## Contributing

The project is not maintained, so issues and pull requests are not monitored. Forks are welcome
under the MIT license.

## License

MIT. See [LICENSE](LICENSE).
