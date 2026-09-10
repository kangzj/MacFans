#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-Debug}"
# launchd only runs the privileged helper when app and helper carry an Apple-issued signature, so set
# FANWRIGHT_SIGNING_IDENTITY to e.g. "Apple Development: Your Name (TEAMID)" for a copy that can control fans.
identity="${FANWRIGHT_SIGNING_IDENTITY:--}"
team=$(echo "$identity" | sed -n 's/.*(\([A-Z0-9]*\)).*/\1/p')
xcodegen generate --quiet
xcodebuild -project Fanwright.xcodeproj -scheme Fanwright -configuration "$configuration" -derivedDataPath build \
  CODE_SIGN_IDENTITY="$identity" DEVELOPMENT_TEAM="$team" build 2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" || true
echo "Built: build/Build/Products/$configuration/Fanwright.app"
