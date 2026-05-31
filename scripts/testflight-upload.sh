#!/usr/bin/env bash
# testflight-upload.sh — Archive, export, and upload Drumrot to TestFlight
#
# Usage:
#   ./scripts/testflight-upload.sh [--bump-build]
#
# Prerequisites:
#   • Xcode with the Drumrot scheme configured for distribution signing
#   • An App Store Connect API key exported in the environment:
#       APP_STORE_CONNECT_API_KEY_ID
#       APP_STORE_CONNECT_API_ISSUER_ID
#       APP_STORE_CONNECT_API_KEY_PATH   (path to the .p8 file)
#   • Or, for legacy password-based auth (xcrun altool):
#       APPLE_ID    (your Apple ID email)
#       APP_PASSWORD  (app-specific password from appleid.apple.com)
#
# The --bump-build flag increments CURRENT_PROJECT_VERSION in the xcodeproj
# before archiving, then commits the bump with a chore: message.
#
# After the upload succeeds:
#   1. Wait ~15 min for Apple processing.
#   2. Open App Store Connect → TestFlight → the build should appear.
#   3. Add it to the "External Beta" group and generate a public link.
#   4. Fill in docs/testing/smoke-notes.md as testers complete their sessions.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$REPO_ROOT/ios/Drumrot.xcodeproj"
SCHEME="Drumrot"
ARCHIVE_PATH="/tmp/Drumrot.xcarchive"
EXPORT_PATH="/tmp/DrumrotExport"
EXPORT_OPTIONS="$REPO_ROOT/scripts/ExportOptions.plist"

# ── helpers ──────────────────────────────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "▸ $*"; }

# ── optional: bump build number ───────────────────────────────────────────────

if [[ "${1:-}" == "--bump-build" ]]; then
  PBXPROJ="$PROJECT/project.pbxproj"
  CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | grep -oE '[0-9]+')
  NEW_BUILD=$((CURRENT_BUILD + 1))
  info "Bumping CFBundleVersion $CURRENT_BUILD → $NEW_BUILD"
  # Update all occurrences of the build number in both Debug and Release configs
  sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT_BUILD;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PBXPROJ"
  git -C "$REPO_ROOT" add "$PBXPROJ"
  git -C "$REPO_ROOT" commit -m "chore: bump CFBundleVersion to $NEW_BUILD (TestFlight)"
  info "Build bumped and committed."
fi

# ── validate environment ──────────────────────────────────────────────────────

USE_API_KEY=false
USE_ALTOOL=false

if [[ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" && \
      -n "${APP_STORE_CONNECT_API_ISSUER_ID:-}" && \
      -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  USE_API_KEY=true
  info "Using App Store Connect API key for upload."
elif [[ -n "${APPLE_ID:-}" && -n "${APP_PASSWORD:-}" ]]; then
  USE_ALTOOL=true
  info "Using altool with app-specific password for upload."
else
  die "No upload credentials found. Set either:
  APP_STORE_CONNECT_API_KEY_ID + APP_STORE_CONNECT_API_ISSUER_ID + APP_STORE_CONNECT_API_KEY_PATH
  or:
  APPLE_ID + APP_PASSWORD"
fi

# ── ExportOptions.plist ───────────────────────────────────────────────────────

if [[ ! -f "$EXPORT_OPTIONS" ]]; then
  info "Creating ExportOptions.plist at $EXPORT_OPTIONS"
  cat > "$EXPORT_OPTIONS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>teamID</key>
    <string>56Q69NYP9H</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
PLIST
fi

# ── archive ───────────────────────────────────────────────────────────────────

info "Archiving $SCHEME …"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  ONLY_ACTIVE_ARCH=NO \
  | xcpretty 2>/dev/null || true   # xcpretty is optional; raw output still printed on failure

[[ -d "$ARCHIVE_PATH" ]] || die "Archive not found at $ARCHIVE_PATH after build."
info "Archive complete: $ARCHIVE_PATH"

# ── export IPA ───────────────────────────────────────────────────────────────

info "Exporting IPA …"
rm -rf "$EXPORT_PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

IPA_PATH=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
[[ -n "$IPA_PATH" ]] || die "No IPA found under $EXPORT_PATH."
info "IPA: $IPA_PATH ($(du -h "$IPA_PATH" | cut -f1))"

# ── upload ────────────────────────────────────────────────────────────────────

if $USE_API_KEY; then
  info "Uploading via xcrun altool with API key …"
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --apiKey  "$APP_STORE_CONNECT_API_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID" \
    --verbose
elif $USE_ALTOOL; then
  info "Uploading via xcrun altool with Apple ID …"
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username "$APPLE_ID" \
    --password "$APP_PASSWORD" \
    --verbose
fi

info ""
info "Upload complete."
info ""
info "Next steps:"
info "  1. Wait ~15 min for Apple to process the build."
info "  2. Open App Store Connect → TestFlight."
info "  3. Add the build to the 'External Beta' group."
info "  4. Enable the public link and share it with ≥3 testers."
info "  5. Fill in docs/testing/smoke-notes.md as testers report back."
