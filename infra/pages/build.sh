#!/usr/bin/env bash
# Cloudflare Pages build script for Flutter Web (VibeCall).
# CF free build timeout ~20 min; first build installs Flutter SDK.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"
FLUTTER_DIR="$HOME/flutter-stable"

if [[ ! -d "$FLUTTER_DIR" ]]; then
  echo "Installing Flutter $FLUTTER_VERSION ..."
  git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics
flutter doctor

cd client
flutter pub get
dart run build_runner build --delete-conflicting-outputs

flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:?}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:?}" \
  --dart-define=ENV="${ENV:-prod}" \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=LIVEKIT_WS_URL="${LIVEKIT_WS_URL:-}"

echo "Build done. Output: client/build/web"
