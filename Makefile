# Convenience targets for ZetaNotes. Each one wraps a script in scripts/.

.PHONY: build run format lint llama release appstore clean

## Build the app with xcodebuild and show only errors, warnings and the result
build:
	scripts/build.sh

## Clean, build and run a Debug build with console output in the terminal
run:
	scripts/run.sh

## Auto-format with SwiftFormat and auto-fix SwiftLint violations
format:
	scripts/format.sh

## Report SwiftLint violations without changing files
lint:
	swiftlint lint ZetaNotes/

## Clone (if needed) and build llama.cpp with Metal support
llama:
	SRCROOT=$(CURDIR) bash scripts/build-llama.sh

## Build, sign, notarize and package a DMG: make release VERSION=1.0.3
release:
	@test -n "$(VERSION)" || { echo "usage: make release VERSION=x.y.z"; exit 1; }
	scripts/release.sh $(VERSION)

## Create an App Store archive and export package
appstore:
	scripts/archive-for-appstore.sh

## Remove Xcode build products for the ZetaNotes scheme
clean:
	xcodebuild -project ZetaNotes.xcodeproj -scheme ZetaNotes clean
