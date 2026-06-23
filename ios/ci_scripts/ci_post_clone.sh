#!/bin/sh
set -e

# Xcode Cloud runs this from ios/ci_scripts/ — move to the repo root.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Flutter is NOT in the Xcode Cloud image — install it.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter precache --ios
flutter pub get

# CocoaPods is usually present; install only if missing.
if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

# Generates ios/Flutter/Generated.xcconfig and bumps the pod/SPM
# deployment target (important for Firebase). Then install pods.
flutter build ios --config-only --release
cd ios && pod install

exit 0
