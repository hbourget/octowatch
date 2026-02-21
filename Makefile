APP_NAME := Octowatch
APP_BUNDLE := $(APP_NAME).app
BIN_PATH := $(shell swift build -c release --show-bin-path 2>/dev/null)

.PHONY: build release bundle run open clean

## Development build
build:
	swift build

## Release build
release:
	swift build -c release

## Build .app bundle (release)
bundle:
	bash Scripts/bundle.sh

## Build bundle and launch the app
run: bundle
	open $(APP_BUNDLE)

## Open an existing bundle (no rebuild)
open:
	open $(APP_BUNDLE)

## Remove build artifacts and app bundle
clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
