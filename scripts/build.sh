#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-Debug}"
xcodegen generate --quiet
xcodebuild -project MacFans.xcodeproj -scheme MacFans -configuration "$configuration" -derivedDataPath build build 2>&1 | grep -E "error:|warning:|BUILD" || true
echo "Built: build/Build/Products/$configuration/MacFans.app"
