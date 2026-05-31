#!/usr/bin/env bash
# scripts/record-preview.sh — Record a 30-second App Store preview video for drumrot
#
# Uses `xcrun simctl io booted recordVideo` to capture the simulator screen at
# native resolution, then trims to 30 s with ffmpeg and re-encodes to the
# App Store-required H.264 .m4v format (no device chrome, no letterboxing).
#
# Usage:
#   ./scripts/record-preview.sh [output-file.m4v]
#
# Default output: ~/Desktop/drumrot-preview.m4v
#
# Prerequisites:
#   • The target simulator is already booted and the app is installed.
#     Run ./scripts/capture-screenshots.sh first — it boots all three simulators.
#   • ffmpeg (brew install ffmpeg) — needed for trim + re-encode.
#     Without ffmpeg the raw .mov is kept and a manual trim note is printed.
#
# Workflow:
#   1. Script starts recording in the background.
#   2. You have 30 seconds to interact with the app in the Simulator window:
#        • Play tab: start a groove, tap a few pads, let the combo climb.
#        • Optionally switch to Library or Drops near the end for variety.
#   3. After 30 s the recording stops automatically.
#   4. ffmpeg trims to exactly 30 s and encodes to .m4v.
#
# App Store video requirements (iPad):
#   • Duration: 15–30 seconds.
#   • Codec: H.264 (Baseline profile recommended).
#   • Resolution: matches your screenshot size for each device slot.
#   • No device chrome, no letterboxing, no transparencies.
#   • File format: .m4v or .mov.

set -euo pipefail

BUNDLE_ID="com.visaliacrc.drumrot"
OUT_M4V="${1:-$HOME/Desktop/drumrot-preview.m4v}"
RAW_MOV="/tmp/drumrot-preview-raw.mov"
DURATION=30

die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "▸ $*"; }

# ── find booted simulator ─────────────────────────────────────────────────────
BOOTED_UDID=$(xcrun simctl list devices booted 2>/dev/null \
    | grep -oE '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}' \
    | head -1 || true)

if [[ -z "$BOOTED_UDID" ]]; then
    die "No booted simulator found. Boot one first, e.g.:
  xcrun simctl boot 'iPad Pro 13-inch (M4)'
  open -a Simulator"
fi

info "Recording from simulator: $BOOTED_UDID"
info "Output: $OUT_M4V"
info ""

# ── launch the app in demo/play mode so it's ready ────────────────────────────
info "Launching drumrot in --demo --play mode..."
xcrun simctl terminate "$BOOTED_UDID" "$BUNDLE_ID" 2>/dev/null || true
sleep 1
xcrun simctl launch "$BOOTED_UDID" "$BUNDLE_ID" --demo --play
sleep 3   # let the Play tab and highway render

# ── start recording ───────────────────────────────────────────────────────────
info ""
info "RECORDING for ${DURATION} seconds..."
info ">>> Switch to the Simulator window NOW and interact with the app. <<<"
info "  Suggested flow:"
info "    0–10 s: tap drum pads, watch combo counter climb"
info "    10–20 s: let a note sequence scroll — show the SP-808 highway"
info "    20–28 s: navigate to Library or Drops tab for variety"
info "    28–30 s: back to Play, final combo display"
info ""

rm -f "$RAW_MOV"
xcrun simctl io "$BOOTED_UDID" recordVideo --codec=h264 "$RAW_MOV" &
RECORD_PID=$!

# Count down
for i in $(seq "$DURATION" -1 1); do
    printf "\r  %2d seconds remaining..." "$i"
    sleep 1
done
printf "\r  Recording done.                    \n"

# Stop recording
kill "$RECORD_PID" 2>/dev/null || true
wait "$RECORD_PID" 2>/dev/null || true
sleep 1   # let the writer flush

[[ -f "$RAW_MOV" ]] || die "Recording file not found at $RAW_MOV"
RAW_SIZE=$(wc -c < "$RAW_MOV" | tr -d ' ')
info "Raw recording: $RAW_MOV (${RAW_SIZE} bytes)"

# ── trim + encode with ffmpeg (if available) ──────────────────────────────────
if command -v ffmpeg &>/dev/null; then
    info "Encoding to .m4v with ffmpeg..."
    ffmpeg -y \
        -i "$RAW_MOV" \
        -t "$DURATION" \
        -vcodec libx264 \
        -profile:v baseline \
        -level 3.1 \
        -pix_fmt yuv420p \
        -acodec aac \
        -b:a 128k \
        -movflags +faststart \
        "$OUT_M4V" \
        2>/dev/null
    info "Encoded: $OUT_M4V"
    rm -f "$RAW_MOV"
else
    info "ffmpeg not found — copying raw .mov as output."
    info "(Install ffmpeg: brew install ffmpeg — then re-encode manually for .m4v)"
    cp "$RAW_MOV" "${OUT_M4V%.m4v}.mov"
    OUT_M4V="${OUT_M4V%.m4v}.mov"
fi

info ""
info "========================================"
info "Preview video saved: $OUT_M4V"
info ""
info "Upload steps:"
info "  1. Log in to appstoreconnect.apple.com → My Apps → drumrot."
info "  2. App Store → iPad → find the device slot you want the preview on."
info "  3. Drag $OUT_M4V into the 'App Preview' area at the top of that slot."
info "  4. App Store Connect will process the video (1–5 min)."
info "  5. Repeat for any other device size slots you want to add a preview to."
info "========================================"
