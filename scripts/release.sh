#!/bin/zsh
# Builds a Release Fanwright.app, signs it, packages a DMG, and optionally notarizes it.
#
#   scripts/release.sh                                   # ad-hoc signed, runs only on this Mac
#   scripts/release.sh --identity "Apple Development" --team TEAMID          # free personal-team certificate
#   scripts/release.sh --identity "Developer ID Application" --team TEAMID   # distributable
#   scripts/release.sh --identity "..." --team TEAMID --notarize-profile fanwright
#
# The notarization profile is created once with:
#   xcrun notarytool store-credentials fanwright --apple-id you@example.com --team-id TEAMID --password app-specific-password
set -euo pipefail
cd "$(dirname "$0")/.."

identity="-"
team=""
notarize_profile=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --identity) identity="$2"; shift 2 ;;
    --team) team="$2"; shift 2 ;;
    --notarize-profile) notarize_profile="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# launchd refuses an ad-hoc signed daemon that has the hardened runtime flag (Launch Constraint Violation),
# so ad-hoc builds ship without it. A real identity keeps hardened runtime, which notarization requires.
hardened_runtime="NO"
if [[ "$identity" != "-" ]]; then
  [[ -n "$team" ]] || { echo "--team TEAMID is required with --identity" >&2; exit 1; }
  hardened_runtime="YES"
fi

xcodegen generate --quiet
rm -rf build/Release dist
xcodebuild -project Fanwright.xcodeproj -scheme Fanwright -configuration Release -derivedDataPath build/Release \
  CODE_SIGN_IDENTITY="$identity" DEVELOPMENT_TEAM="$team" OTHER_CODE_SIGN_FLAGS="--timestamp" \
  ENABLE_HARDENED_RUNTIME="$hardened_runtime" ARCHS=arm64 build 2>&1 \
  | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" || true

app="build/Release/Build/Products/Release/Fanwright.app"
[[ -d "$app" ]] || { echo "Build failed" >&2; exit 1; }
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app/Contents/Info.plist")
codesign --verify --deep --strict --verbose=2 "$app"

mkdir -p dist/stage
cp -R "$app" dist/stage/
ln -s /Applications dist/stage/Applications
dmg="dist/Fanwright-$version.dmg"
hdiutil create -volname "Fanwright" -srcfolder dist/stage -ov -format UDZO "$dmg" >/dev/null
rm -rf dist/stage

if [[ -n "$notarize_profile" ]]; then
  xcrun notarytool submit "$dmg" --keychain-profile "$notarize_profile" --wait
  xcrun stapler staple "$dmg"
  spctl --assess --type open --context context:primary-signature -v "$dmg"
fi

echo "Release: $dmg"
if [[ "$identity" == "-" ]]; then
  echo "Ad-hoc signed: other Macs need the Open Anyway steps from the README. Pass --identity for a distributable build."
fi
