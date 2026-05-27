#!/bin/sh

# Change working directory to the root of your cloned repo.
cd $CI_PRIMARY_REPOSITORY_PATH

set -ex
set -euo pipefail

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods

# Install CocoaPods dependencies.
cd ios && pod install

# Default to "production" unless matched
MODE="production"
if [ "${CI_WORKFLOW:-}" = "Master - Public Testing" ]; then
  MODE="production"
elif [ "${CI_WORKFLOW:-}" = "Test - Internal Testing" ]; then
  MODE="test"
fi

flutter build ios --config-only --release --dart-define="deployment-mode=$MODE"

# Refresh Package.resolved so Xcode Cloud (which has automatic SPM resolution
# disabled) doesn't reject the build when Flutter plugins change iOS deps.
xcodebuild -workspace Runner.xcworkspace -scheme Runner -resolvePackageDependencies

exit 0