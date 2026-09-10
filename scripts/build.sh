#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-Debug}"
xcodegen generate --quiet
xcodebuild -project Fanwright.xcodeproj -scheme Fanwright -configuration "$configuration" -derivedDataPath build build 2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" || true
echo "Built: build/Build/Products/$configuration/Fanwright.app"
