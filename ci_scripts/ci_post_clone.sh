#!/bin/sh

# Xcode Cloud post-clone script.
#
# Xcode Cloud checks out the repo and builds without running CocoaPods or
# Flutter's pub get. ios/Pods (and the generated *.xcfilelist files the build
# references) are gitignored, so they are absent on a fresh checkout and the
# archive fails with:
#   "Unable to load contents of file list: .../Pods-Runner-*-output-files.xcfilelist"
#
# This script regenerates the Flutter + CocoaPods artifacts after clone so the
# Xcode build has everything it needs. Xcode Cloud runs ci_scripts/ci_post_clone.sh
# automatically if it exists.

set -e

echo "===== ci_post_clone: setting up Flutter + CocoaPods ====="

# --- Install Flutter (Xcode Cloud images do not ship Flutter) ---
# Pin to the channel/version the app is built with locally.
FLUTTER_VERSION="3.44.0"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Cloning Flutter $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter precache --ios

# --- Resolve Dart/Flutter packages (generates ios/Flutter/Generated.xcconfig etc.) ---
# Run from the repo root (Xcode Cloud sets CI_PRIMARY_REPOSITORY_PATH).
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

# --- Install CocoaPods dependencies (generates Pods/ + the .xcfilelist files) ---
# Ensure CocoaPods is available.
if ! command -v pod >/dev/null 2>&1; then
  echo "Installing CocoaPods..."
  export HOMEBREW_NO_INSTALL_CLEANUP=1
  brew install cocoapods
fi

cd "$CI_PRIMARY_REPOSITORY_PATH/ios"
pod install --repo-update

echo "===== ci_post_clone: done ====="
