#!/usr/bin/env bash
# =============================================================================
# scripts/validate_firebase.sh
# =============================================================================
# Checks that the Firebase credential files exist and do NOT contain the
# placeholder values from the templates.
#
# Usage:
#   bash scripts/validate_firebase.sh          # exits 0 on success, 1 on error
#   bash scripts/validate_firebase.sh --warn   # exits 0 even with warnings
#
# Add to CI pre-build step or Makefile to catch missing credentials early.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

IOS_DEST="$REPO_ROOT/ios/Runner/GoogleService-Info.plist"
ANDROID_DEST="$REPO_ROOT/android/app/google-services.json"

WARN_ONLY=false
if [[ "${1:-}" == "--warn" ]]; then
  WARN_ONLY=true
fi

ERRORS=0

echo ""
echo "============================================="
echo "  Voom – Firebase Config Validation"
echo "============================================="
echo ""

# ── Helper ────────────────────────────────────────────────────────────────────
fail() {
  echo "❌  $1"
  ERRORS=$((ERRORS + 1))
}

ok() {
  echo "✅  $1"
}

# ── iOS ───────────────────────────────────────────────────────────────────────
echo "iOS → $IOS_DEST"
if [ ! -f "$IOS_DEST" ]; then
  fail "ios/Runner/GoogleService-Info.plist is MISSING."
  echo "     Run: bash scripts/setup_firebase.sh"
elif grep -q "REPLACE_WITH_YOUR_" "$IOS_DEST"; then
  fail "ios/Runner/GoogleService-Info.plist still contains placeholder values."
  echo "     Download the real file from Firebase Console and overwrite this file."
else
  ok "ios/Runner/GoogleService-Info.plist looks real (no placeholder values found)."
fi

echo ""

# ── Android ───────────────────────────────────────────────────────────────────
echo "Android → $ANDROID_DEST"
if [ ! -f "$ANDROID_DEST" ]; then
  fail "android/app/google-services.json is MISSING."
  echo "     Run: bash scripts/setup_firebase.sh"
elif grep -q "REPLACE_WITH_YOUR_" "$ANDROID_DEST"; then
  fail "android/app/google-services.json still contains placeholder values."
  echo "     Download the real file from Firebase Console and overwrite this file."
else
  ok "android/app/google-services.json looks real (no placeholder values found)."
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
if [ "$ERRORS" -gt 0 ]; then
  echo "─────────────────────────────────────────────"
  echo "  $ERRORS problem(s) found."
  echo "  The app will crash on launch without valid Firebase credentials."
  echo "─────────────────────────────────────────────"
  echo ""
  if [ "$WARN_ONLY" = true ]; then
    exit 0
  else
    exit 1
  fi
else
  echo "─────────────────────────────────────────────"
  echo "  All Firebase config files look good. ✅"
  echo "─────────────────────────────────────────────"
  echo ""
  exit 0
fi
