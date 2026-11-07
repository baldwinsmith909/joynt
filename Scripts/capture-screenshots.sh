#!/usr/bin/env bash
# Boot simulator, launch Joynt in demo mode, capture feed / composer / profile / sign-in.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MEDIA_DIR="${MEDIA_DIR:-/Users/baldwinsmith/Library/Application Support/Cursor/AgentStores/cursor_agent_stores/bc-9c2ae9ed-a261-48d2-8ff7-029d3b98368f/files/media}"
BUNDLE_ID="com.joynt.app"
SCHEME="Joynt"
PROJECT="$ROOT/Joynt.xcodeproj"

mkdir -p "$MEDIA_DIR" "$ROOT/Scripts/.capture-tmp"

DEVICE_ID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone 17 \(/ {print $2; exit}')"
if [[ -z "${DEVICE_ID:-}" ]]; then
  DEVICE_ID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ && /Shutdown|Booted/ {print $2; exit}')"
fi
if [[ -z "${DEVICE_ID:-}" ]]; then
  echo "No available iPhone simulator. Install an iOS runtime first." >&2
  exit 1
fi

echo "Using simulator $DEVICE_ID"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b

cd "$ROOT"
xcodegen generate
xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$ROOT/Scripts/.capture-tmp/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build

APP="$(find "$ROOT/Scripts/.capture-tmp/DerivedData/Build/Products" -name 'Joynt.app' -type d | head -1)"
test -n "$APP"

shot_tab() {
  local tab="$1"
  local out="$2"
  xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$DEVICE_ID" "$APP"
  SIMCTL_CHILD_JOYNT_DEMO=1 SIMCTL_CHILD_JOYNT_TAB="$tab" \
    xcrun simctl launch --terminate-running-process "$DEVICE_ID" "$BUNDLE_ID"
  sleep 3.2
  xcrun simctl io "$DEVICE_ID" screenshot "$out"
  echo "Wrote $out"
}

shot_tab feed "$MEDIA_DIR/joynt-feed.png"
shot_tab post "$MEDIA_DIR/joynt-composer.png"
shot_tab profile "$MEDIA_DIR/joynt-profile.png"

xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE_ID" "$APP"
xcrun simctl launch --terminate-running-process "$DEVICE_ID" "$BUNDLE_ID"
sleep 2.5
xcrun simctl io "$DEVICE_ID" screenshot "$MEDIA_DIR/joynt-signin.png"
echo "Wrote $MEDIA_DIR/joynt-signin.png"
echo "Screenshots ready in $MEDIA_DIR"
