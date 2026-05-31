#!/usr/bin/env bash
# scripts/capture-screenshots.sh — Capture App Store screenshots for drumrot
#
# Produces 5 screenshots per required device class:
#   • iPad Pro 13" (M4)    — 2064 × 2752 px (required)
#   • iPad Pro 12.9" 6th   — 2048 × 2732 px (required)
#   • iPad Pro 11" (M4)    — 1668 × 2388 px (required)
#
# Usage:
#   ./scripts/capture-screenshots.sh [output-dir]
#
# Output directory defaults to ~/Desktop/drumrot-screenshots/
# Each file is named: <device-slug>/<screen-name>.png
#
# Prerequisites:
#   • Xcode installed with the required simulators downloaded
#   • Drumrot.xcodeproj builds cleanly (run `xcodebuild build` first if unsure)
#
# The screenshots are landscape — the sim device is portrait so simctl output
# is rotated 90°. Upload them as-is; App Store Connect accepts landscape PNGs.

set -euo pipefail

SCHEME="Drumrot"
BUNDLE_ID="com.visaliacrc.drumrot"
OUT_DIR="${1:-$HOME/Desktop/drumrot-screenshots}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$REPO_ROOT/ios/Drumrot.xcodeproj"

# ── Device matrix ─────────────────────────────────────────────────────────────
# Format: "Simulator Name|slug"
DEVICES=(
    "iPad Pro 13-inch (M4)|ipad-pro-13-m4"
    "iPad Pro 12.9-inch (6th generation)|ipad-pro-12-9-6th"
    "iPad Pro 11-inch (M4)|ipad-pro-11-m4"
)

# ── Screens to capture ────────────────────────────────────────────────────────
# Format: "tab-flag|output-filename|sleep-seconds"
# We capture 5 screens per device (Play, Library, Drops, Progress, Builder).
SCREENS=(
    "--demo --play|01-play|5"
    "--demo --library|02-library|4"
    "--demo --drops|03-drops|4"
    "--demo --progress|04-progress|4"
    "--demo --build|05-builder|4"
)

# ── helpers ───────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "▸ $*"; }

find_udid() {
    local name="$1"
    xcrun simctl list devices available 2>/dev/null \
        | grep -F "$name" | head -1 \
        | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' \
        || true
}

boot_sim() {
    local udid="$1"
    local state
    state=$(xcrun simctl list devices 2>/dev/null \
        | grep "$udid" | grep -oE 'Booted|Shutdown' || echo "Shutdown")
    if [[ "$state" != "Booted" ]]; then
        info "  Booting $udid..."
        xcrun simctl boot "$udid"
        xcrun simctl bootstatus "$udid" -b > /dev/null 2>&1 || sleep 10
    fi
}

build_app() {
    local sim_name="$1"
    info "Building Drumrot for: $sim_name"
    BUILD_OUTPUT=$(xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -configuration Release \
        -destination "platform=iOS Simulator,name=$sim_name" \
        ONLY_ACTIVE_ARCH=NO \
        build 2>&1)
    if echo "$BUILD_OUTPUT" | grep -q "BUILD FAILED"; then
        echo "$BUILD_OUTPUT" | grep -E "error:" | head -20
        die "Build failed for $sim_name"
    fi
    # Extract app path from build settings
    BUILT_PRODUCTS_DIR=$(xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -configuration Release \
        -showBuildSettings 2>/dev/null \
        | awk '/^\s*BUILT_PRODUCTS_DIR/{print $3}' | head -1)
    echo "$BUILT_PRODUCTS_DIR/Drumrot.app"
}

# ── Main ──────────────────────────────────────────────────────────────────────
mkdir -p "$OUT_DIR"
info "Output: $OUT_DIR"
info ""

# Build once — the simulator binary works across all iPad sim devices
FIRST_SIM_NAME=$(echo "${DEVICES[0]}" | cut -d'|' -f1)
APP_PATH=$(build_app "$FIRST_SIM_NAME")
[[ -d "$APP_PATH" ]] || die "App not found at $APP_PATH after build"
info "App: $APP_PATH"
info ""

TOTAL_PASS=0
TOTAL_FAIL=0

for device_entry in "${DEVICES[@]}"; do
    SIM_NAME=$(echo "$device_entry" | cut -d'|' -f1)
    SLUG=$(echo "$device_entry" | cut -d'|' -f2)

    info "========================================"
    info "Device: $SIM_NAME ($SLUG)"
    info "========================================"

    UDID=$(find_udid "$SIM_NAME")
    if [[ -z "$UDID" ]]; then
        info "  WARNING: simulator '$SIM_NAME' not found — skipping."
        info "  Install it via: Xcode > Settings > Platforms > iOS Simulators"
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        continue
    fi
    info "  UDID: $UDID"

    boot_sim "$UDID"

    # Install app
    xcrun simctl install "$UDID" "$APP_PATH"

    DEVICE_OUT="$OUT_DIR/$SLUG"
    mkdir -p "$DEVICE_OUT"

    for screen_entry in "${SCREENS[@]}"; do
        FLAGS_STR=$(echo "$screen_entry" | cut -d'|' -f1)
        FNAME=$(echo "$screen_entry" | cut -d'|' -f2)
        WAIT=$(echo "$screen_entry" | cut -d'|' -f3)

        # Terminate any previous instance
        xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
        sleep 1

        # Launch with tab flags
        # shellcheck disable=SC2086
        xcrun simctl launch "$UDID" "$BUNDLE_ID" $FLAGS_STR

        sleep "$WAIT"

        OUT_FILE="$DEVICE_OUT/${FNAME}.png"
        if xcrun simctl io "$UDID" screenshot "$OUT_FILE" 2>/dev/null; then
            SIZE=$(wc -c < "$OUT_FILE" | tr -d ' ')
            info "  -> $FNAME.png (${SIZE} bytes)"
            if [[ "$SIZE" -lt 10000 ]]; then
                info "     WARNING: file is suspiciously small — may be blank"
                TOTAL_FAIL=$((TOTAL_FAIL + 1))
            else
                TOTAL_PASS=$((TOTAL_PASS + 1))
            fi
        else
            info "  ERROR: screenshot failed for $FNAME"
            TOTAL_FAIL=$((TOTAL_FAIL + 1))
        fi
    done

    # Shut down to free memory before next device
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    info ""
done

# ── Summary ───────────────────────────────────────────────────────────────────
info "========================================"
info "Summary: $TOTAL_PASS captured, $TOTAL_FAIL failed"
info "Output:  $OUT_DIR"
info ""
info "Next steps:"
info "  1. Open $OUT_DIR and verify each screenshot looks correct."
info "  2. Log in to appstoreconnect.apple.com → My Apps → drumrot."
info "  3. App Store → iPad → drag screenshots into each device slot:"
info "       ipad-pro-13-m4/       → '13\" iPad Pro' slot"
info "       ipad-pro-12-9-6th/    → '12.9\" iPad Pro' slot"
info "       ipad-pro-11-m4/       → '11\" iPad Pro' slot"
info "  4. Record the 30 s preview (see scripts/record-preview.sh)."
info "  5. Upload the preview .m4v in the 'App Preview' slot."
info "  6. Click Save → Add for Review."
info "========================================"

if [[ "$TOTAL_FAIL" -gt 0 ]]; then
    exit 1
fi
