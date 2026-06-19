#!/bin/sh

# Xcode Cloud post-clone script (Flutter iOS).
#
# MUST live at ios/ci_scripts/ci_post_clone.sh — for a Flutter app the Xcode
# project is in ios/, so Xcode Cloud looks for ci_scripts/ there (NOT at the
# repo root). Xcode Cloud runs this automatically after cloning.
#
# Why this is required: Xcode Cloud builds from a fresh checkout and does not
# run Flutter or CocoaPods. ios/Pods and the generated *.xcfilelist files are
# gitignored, so the archive fails with:
#   "Unable to load contents of file list: .../Pods-Runner-*-files.xcfilelist"
# This script regenerates the Flutter + CocoaPods artifacts so the build works.

# Fail the build if any command fails.
set -e

echo "===== ci_post_clone: Flutter + CocoaPods setup ====="

# The default working directory for this script is ios/ci_scripts.
# Move to the repo root (Xcode Cloud provides CI_PRIMARY_REPOSITORY_PATH).
cd "$CI_PRIMARY_REPOSITORY_PATH"

# --- Install Flutter ---
# Pin to the exact version the app is built with locally to avoid toolchain
# drift between local archives and CI.
FLUTTER_VERSION="3.44.0"
git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter --version
flutter precache --ios

# --- Resolve Flutter/Dart packages (generates ios/Flutter/Generated.xcconfig) ---
flutter pub get

# --- Install CocoaPods + pods (generates Pods/ and the .xcfilelist files) ---
HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods

cd ios
pod install

echo "===== ci_post_clone: done ====="
exit 0
