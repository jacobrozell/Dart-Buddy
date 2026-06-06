#!/bin/sh
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install XcodeGen (same as GitHub Actions CI)
brew install xcodegen

# Generate DartBuddy.xcodeproj from project.yml
xcodegen generate

# Materialize Firebase plist from Xcode Cloud secret (see docs/release/xcode-cloud.md)
if [ -n "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
  echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode \
    > Resources/GoogleService-Info.plist
else
  echo "warning: GOOGLE_SERVICE_INFO_PLIST_BASE64 not set; using example plist"
  cp Resources/GoogleService-Info.plist.example Resources/GoogleService-Info.plist
fi
