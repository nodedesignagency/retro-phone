#!/usr/bin/env bash
# Builds Retro Phone and launches it in the iOS Simulator.
#
#   ./scripts/run.sh                           newest available iPhone simulator
#   SIMULATOR="iPhone 16 Pro" ./scripts/run.sh pick one by name
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT=RetroPhone.xcodeproj
SCHEME=RetroPhone
BUNDLE_ID=com.nodedesign.RetroPhone
DERIVED_DATA=.build/DerivedData
UUID_PATTERN='[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'

if ! xcrun --find xcodebuild >/dev/null 2>&1; then
  echo "Xcode isn't installed or selected. Install Xcode, then run:" >&2
  echo "  sudo xcode-select -s /Applications/Xcode.app" >&2
  exit 1
fi

devices=$(xcrun simctl list devices available)
if [[ -n "${SIMULATOR:-}" ]]; then
  line=$(grep -F "    $SIMULATOR (" <<<"$devices" | tail -1 || true)
else
  # The newest iOS runtime is listed last; prefer a Pro model.
  line=$(grep -E '^ +iPhone .*Pro \(' <<<"$devices" | tail -1 || true)
  [[ -z "$line" ]] && line=$(grep -E '^ +iPhone ' <<<"$devices" | tail -1 || true)
fi
udid=$(grep -oE "$UUID_PATTERN" <<<"$line" | head -1 || true)
if [[ -z "$udid" ]]; then
  echo "No iPhone simulator found. In Xcode, open Settings > Components and add an iOS simulator." >&2
  exit 1
fi
name=$(sed -E "s/ \($UUID_PATTERN\).*//; s/^ +//" <<<"$line")

echo "Building Retro Phone for $name…"
xcrun simctl boot "$udid" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$udid"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination "id=$udid" -derivedDataPath "$DERIVED_DATA" -quiet build

xcrun simctl install "$udid" "$DERIVED_DATA/Build/Products/Debug-iphonesimulator/RetroPhone.app"
xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
echo "Retro Phone is running on $name."
