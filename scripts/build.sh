#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-Debug}"
# launchd only runs the privileged helper when app and helper carry an Apple-issued signature, so set
# FANWRIGHT_SIGNING_IDENTITY="Apple Development" and FANWRIGHT_SIGNING_TEAM=TEAMID for a copy that controls fans.
identity="${FANWRIGHT_SIGNING_IDENTITY:--}"
team="${FANWRIGHT_SIGNING_TEAM:-}"
xcodegen generate --quiet
xcodebuild -project Fanwright.xcodeproj -scheme Fanwright -configuration "$configuration" -derivedDataPath build \
  CODE_SIGN_IDENTITY="$identity" DEVELOPMENT_TEAM="$team" build 2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" || true
echo "Built: build/Build/Products/$configuration/Fanwright.app"
