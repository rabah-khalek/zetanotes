# Scripts

Build, release and maintenance tooling for ZetaNotes. Every script runs from the repository root
and the `Makefile` at the root wraps the common ones (`make build`, `make run`, `make format`,
`make llama`, `make release VERSION=x.y.z`, `make appstore`).

## Development

| Script | Purpose |
| --- | --- |
| `setup-dev.sh` | One-time setup: checks Xcode and Homebrew tools, clones and builds llama.cpp. |
| `build-llama.sh` | Builds llama.cpp with Metal support into `llama.cpp/build`. Also run by an Xcode build phase, so a plain Xcode build works once `llama.cpp/` exists. |
| `build.sh` | `xcodebuild` wrapper that prints only errors, warnings and the result. |
| `run.sh` | Cleans, builds and launches a Debug build with console output. |
| `format.sh` | Runs SwiftFormat and SwiftLint auto-fix over `ZetaNotes/`, then reports what is left. |
| `generate-app-icons.py` | Regenerates `AppIcon.appiconset` from `docs/logo.png`. Needs Pillow (`pip install pillow`). |

## Release (Developer ID DMG)

`release.sh <version>` builds a Release configuration, signs it with the Developer ID certificate,
notarizes it, staples the ticket and packages a DMG with a SHA-256 checksum into
`releases/ZetaNotes-Release-<timestamp>/`. It is split into `lib/`:

| File | Step |
| --- | --- |
| `release-config.sh` | App name, scheme, team ID, signing identity, download URL. |
| `lib/validation.sh` | Checks tools, certificates and credentials before building. |
| `lib/xcode.sh` | Archives the app and builds llama.cpp first. |
| `lib/signing.sh` | Deep-signs the app and bundled dylibs with the hardened runtime. |
| `lib/notarization.sh` | Submits the DMG to Apple's notary service and staples the ticket. |
| `lib/packaging.sh` | Creates the DMG (`brew install create-dmg`) and the checksum file. |
| `lib/sparkle.sh` | Stubs left from the removed Sparkle auto-update support. |
| `verify-signatures.sh` | Checks code signatures and Gatekeeper acceptance of a built app or DMG. |

Credentials are read from the environment, never from the repository. Use either an App Store
Connect API key:

```bash
export ASC_KEY_PATH=~/.private_keys/AuthKey_XXXXXXXXXX.p8
export ASC_KEY_ID=XXXXXXXXXX
export ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000
```

or an Apple ID with an app-specific password:

```bash
export APPLE_ID=you@example.com
export APPLE_TEAM_ID=XXXXXXXXXX
export APPLE_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx
```

## App Store

`archive-for-appstore.sh` builds an archive signed with the Apple Distribution certificate and
exports an App Store package into `build/AppStore/`. Upload it with Transporter, or export the
archive from Xcode's Organizer. `copy-dsyms-to-archive.sh` adds the llama.cpp dSYMs to an archive
so crash reports symbolicate.

All of this needs an active Apple Developer membership. The 1.0.3 release was the last one, so these
scripts are kept for reference and for forks.
