#!/bin/sh
set -e

# Xcode Cloud runs this from ios/ci_scripts/ — move to the repo root.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Flutter is NOT in the Xcode Cloud image — install it.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Force CocoaPods (matches your local build). SPM integration fails on CI
# because there's no committed Package.resolved.
flutter config --no-enable-swift-package-manager

flutter precache --ios
flutter pub get

if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

flutter build ios --config-only --release
cd ios && pod install

exit 0
