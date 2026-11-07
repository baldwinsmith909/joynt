#!/usr/bin/env bash
# Boot simulator, launch Joynt in demo mode, capture feed / composer / profile.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MEDIA_DIR="${MEDIA_DIR:-/Users/baldwinsmith/Library/Application Support/Cursor/AgentStores/cursor_agent_stores/bc-9c2ae9ed-a261-48d2-8ff7-029d3b98368f/files/media}"
BUNDLE_ID="com.joynt.app"
SCHEME="Joynt"
PROJECT="$ROOT/Joynt.xcodeproj"

mkdir -p "$MEDIA_DIR" "$ROOT/Scripts/.capture-tmp"

# Prefer an available iPhone simulator
DEVICE_ID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ && /Shutdown|Booted/ {print $2; exit}')"
if [[ -z "${DEVICE_ID:-}" ]]; then
  echo "No available iPhone simulator. Install an iOS runtime first." >&2
  exit 1
fi

echo "Using simulator $DEVICE_ID"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b

DEST="platform=iOS Simulator,id=$DEVICE_ID"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DEST" -derivedDataPath "$ROOT/Scripts/.capture-tmp/DerivedData" build

APP="$(find "$ROOT/Scripts/.capture-tmp/DerivedData/Build/Products" -name 'Joynt.app' -type d | head -1)"
test -n "$APP"

install_and_shot() {
  local args="$1"
  local out="$2"
  xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$DEVICE_ID" "$APP"
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  # shellcheck disable=SC2086
  xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" $args
  sleep 2.5
  xcrun simctl io "$DEVICE_ID" screenshot "$out"
  echo "Wrote $out"
}

install_and_shot "-demoAuto" "$MEDIA_DIR/joynt-feed.png"
install_and_shot "-demoAuto -tabPost" "$MEDIA_DIR/joynt-composer.png"
install_and_shot "-demoAuto -tabProfile" "$MEDIA_DIR/joynt-profile.png"

echo "Screenshots ready in $MEDIA_DIR"
