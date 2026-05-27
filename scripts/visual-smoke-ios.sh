#!/usr/bin/env bash
# scripts/visual-smoke-ios.sh
#
# Visual smoke test for the Drumrot iOS app.
# Boots the iPad (A16) simulator, installs the app, launches each tab via the
# --demo + --<tab> debug flags, and captures a screenshot per tab with simctl.
#
# Usage:
#   ./scripts/visual-smoke-ios.sh [output-dir]          # builds app first
#   ./scripts/visual-smoke-ios.sh [output-dir] [app-path] # skips build, uses existing .app
#
# Screenshots come out rotated 90° — the app is landscape-locked on a portrait
# simulator device. This is expected. Rotate the Simulator window to verify
# orientation, but the raw PNG is rotated for layout-correctness checks.
#
# Exit codes:
#   0  all tabs screenshotted, no launch failure
#   1  build, install, or launch failed

set -euo pipefail

SCHEME="Drumrot"
BUNDLE_ID="com.visaliacrc.drumrot"
SIMULATOR_NAME="iPad (A16)"
OUT_DIR="${1:-/tmp/drumrot-visual-smoke}"
EXPLICIT_APP="${2:-}"

cd "$(dirname "$0")/.."   # repo root

mkdir -p "$OUT_DIR"

# ── 1. Resolve app path ───────────────────────────────────────────────────────
if [[ -n "$EXPLICIT_APP" ]]; then
    APP_PATH="$EXPLICIT_APP"
    echo "Using provided app: $APP_PATH"
else
    echo ">>> Building Drumrot for iOS Simulator..."
    BUILD_SETTINGS=$(xcodebuild \
        -project ios/Drumrot.xcodeproj \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -configuration Debug \
        -showBuildSettings 2>/dev/null)
    BUILT_PRODUCTS_DIR=$(echo "$BUILD_SETTINGS" | awk '/BUILT_PRODUCTS_DIR/{print $3}' | head -1)

    xcodebuild \
        -project ios/Drumrot.xcodeproj \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -configuration Debug \
        -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
        build 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"

    APP_PATH="$BUILT_PRODUCTS_DIR/Drumrot.app"
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: app not found at $APP_PATH" >&2
    exit 1
fi
echo "App: $APP_PATH"

# ── 2. Boot simulator ─────────────────────────────────────────────────────────
echo ">>> Booting $SIMULATOR_NAME..."
DEVICE_ID=$(xcrun simctl list devices available 2>/dev/null \
    | grep -F "$SIMULATOR_NAME" | head -1 \
    | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')

if [[ -z "$DEVICE_ID" ]]; then
    echo "ERROR: could not find simulator '$SIMULATOR_NAME'" >&2
    exit 1
fi
echo "Device: $DEVICE_ID"

STATE=$(xcrun simctl list devices 2>/dev/null | grep "$DEVICE_ID" | grep -oE 'Booted|Shutdown' || echo "Shutdown")
if [[ "$STATE" != "Booted" ]]; then
    xcrun simctl boot "$DEVICE_ID"
    echo "Waiting for simulator to finish booting..."
    xcrun simctl bootstatus "$DEVICE_ID" -b > /dev/null 2>&1 || sleep 8
fi
echo "Simulator booted."

# ── 3. Install app ────────────────────────────────────────────────────────────
echo ">>> Installing app..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

# ── 4. Screenshot each tab ────────────────────────────────────────────────────
# All flags require --demo (they are inside the --demo guard in DrumrotApp.swift).
# --demo seeds 4 collected drumrots, 1 lesson score, 2 play-days, 2 unlocks.
TABS="play library progress build drops"

FAILED=0
for tab in $TABS; do
    echo ">>> Tab: $tab"

    # Terminate any existing instance
    xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
    sleep 1

    # Resolve per-tab launch flags
    case "$tab" in
        play)     FLAGS=(--demo --play)     ;;
        library)  FLAGS=(--demo --library)  ;;
        progress) FLAGS=(--demo --progress) ;;
        build)    FLAGS=(--demo --build)    ;;
        drops)    FLAGS=(--demo --drops)    ;;
        *)        FLAGS=(--demo)            ;;
    esac

    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" "${FLAGS[@]}"

    # Wait for UI to render (landscape-locked app needs a moment after launch)
    sleep 4

    OUT_FILE="$OUT_DIR/tab-${tab}.png"
    if xcrun simctl io "$DEVICE_ID" screenshot "$OUT_FILE"; then
        SIZE=$(wc -c < "$OUT_FILE" | tr -d ' ')
        echo "  -> $OUT_FILE (${SIZE} bytes)"
        if [[ "$SIZE" -lt 10000 ]]; then
            echo "  WARNING: screenshot suspiciously small — may be blank or crashed"
            FAILED=1
        fi
    else
        echo "  ERROR: screenshot failed for tab $tab" >&2
        FAILED=1
    fi
done

# Terminate cleanly
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true

# ── 5. Summary ────────────────────────────────────────────────────────────────
echo ""
echo "=== Visual smoke screenshots → $OUT_DIR ==="
ls -lh "$OUT_DIR"/*.png 2>/dev/null || true
echo ""
echo "NOTE: Screenshots are rotated 90° (landscape-locked app on portrait sim)."
echo "      This is expected — see project-state.md sim-capture note."

if [[ "$FAILED" -ne 0 ]]; then
    echo "RESULT: FAIL — one or more tabs did not screenshot cleanly." >&2
    exit 1
fi
echo "RESULT: PASS — all tabs screenshotted."
