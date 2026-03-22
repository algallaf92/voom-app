#!/usr/bin/env bash
# =============================================================================
# scripts/setup_firebase.sh
# =============================================================================
# Copies the Firebase credential templates to their expected locations so that
# Flutter can build for iOS and Android.
#
# Run this once after cloning the repo:
#   bash scripts/setup_firebase.sh
#
# After running this script, REPLACE the placeholder values in:
#   • ios/Runner/GoogleService-Info.plist
#   • android/app/google-services.json
# with the real values downloaded from the Firebase Console.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

IOS_TEMPLATE="$REPO_ROOT/ios/Runner/GoogleService-Info.plist.template"
IOS_DEST="$REPO_ROOT/ios/Runner/GoogleService-Info.plist"

ANDROID_TEMPLATE="$REPO_ROOT/android/app/google-services.json.template"
ANDROID_DEST="$REPO_ROOT/android/app/google-services.json"

echo ""
echo "============================================="
echo "  Voom – Firebase Setup"
echo "============================================="
echo ""

# ── iOS ───────────────────────────────────────────────────────────────────────
if [ -f "$IOS_DEST" ]; then
  echo "✅  ios/Runner/GoogleService-Info.plist already exists — skipping copy."
else
  cp "$IOS_TEMPLATE" "$IOS_DEST"
  echo "📄  Created ios/Runner/GoogleService-Info.plist from template."
fi

# ── Android ───────────────────────────────────────────────────────────────────
if [ -f "$ANDROID_DEST" ]; then
  echo "✅  android/app/google-services.json already exists — skipping copy."
else
  cp "$ANDROID_TEMPLATE" "$ANDROID_DEST"
  echo "📄  Created android/app/google-services.json from template."
fi

echo ""
echo "─────────────────────────────────────────────"
echo "  Next steps"
echo "─────────────────────────────────────────────"
echo ""
echo "  1. Open https://console.firebase.google.com/ and select your project."
echo ""
echo "  2. iOS:"
echo "     • Project Settings → Your apps → iOS+ app"
echo "     • Download GoogleService-Info.plist"
echo "     • Overwrite: ios/Runner/GoogleService-Info.plist"
echo ""
echo "  3. Android:"
echo "     • Project Settings → Your apps → Android app"
echo "     • Download google-services.json"
echo "     • Overwrite: android/app/google-services.json"
echo ""
echo "  4. Validate both files:"
echo "     bash scripts/validate_firebase.sh"
echo ""
echo "  ⚠️   IMPORTANT: These files contain API keys."
echo "       They are listed in .gitignore and must NEVER be committed."
echo ""
