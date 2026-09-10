#!/bin/zsh
# Builds a Release MacFans.app, signs it, packages a DMG, and optionally notarizes it.
#
#   scripts/release.sh                                   # ad-hoc signed, runs only on this Mac
#   scripts/release.sh --identity "Developer ID Application: Jasper Kang (TEAMID)"
#   scripts/release.sh --identity "..." --notarize-profile macfans
#
# The notarization profile is created once with:
#   xcrun notarytool store-credentials macfans --apple-id you@example.com --team-id TEAMID --password app-specific-password
set -euo pipefail
cd "$(dirname "$0")/.."

identity="-"
notarize_profile=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --identity) identity="$2"; shift 2 ;;
    --notarize-profile) notarize_profile="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

team=""
if [[ "$identity" != "-" ]]; then
  team=$(echo "$identity" | sed -n 's/.*(\([A-Z0-9]*\)).*/\1/p')
  [[ -n "$team" ]] || { echo "Could not read the Team ID from the identity string" >&2; exit 1; }
fi

xcodegen generate --quiet
rm -rf build/Release dist
xcodebuild -project MacFans.xcodeproj -scheme MacFans -configuration Release -derivedDataPath build/Release \
  CODE_SIGN_IDENTITY="$identity" DEVELOPMENT_TEAM="$team" OTHER_CODE_SIGN_FLAGS="--timestamp" build 2>&1 \
  | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" || true

app="build/Release/Build/Products/Release/MacFans.app"
[[ -d "$app" ]] || { echo "Build failed" >&2; exit 1; }
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app/Contents/Info.plist")
codesign --verify --deep --strict --verbose=2 "$app"

mkdir -p dist/stage
cp -R "$app" dist/stage/
ln -s /Applications dist/stage/Applications
dmg="dist/MacFans-$version.dmg"
hdiutil create -volname "MacFans" -srcfolder dist/stage -ov -format UDZO "$dmg" >/dev/null
rm -rf dist/stage

if [[ -n "$notarize_profile" ]]; then
  xcrun notarytool submit "$dmg" --keychain-profile "$notarize_profile" --wait
  xcrun stapler staple "$dmg"
  spctl --assess --type open --context context:primary-signature -v "$dmg"
fi

echo "Release: $dmg"
[[ "$identity" == "-" ]] && echo "Ad-hoc signed: this DMG runs on this Mac only. Pass --identity for a distributable build."
