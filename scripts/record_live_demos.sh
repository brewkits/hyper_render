#!/usr/bin/env bash
# =============================================================================
# Automated High-Quality Demo GIF Recorder for iOS Simulator
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/assets"
TMP="$ROOT/.demo_recordings"
mkdir -p "$TMP" "$ASSETS"

UDID="52415E8D-5DC0-421F-A5B2-F08E6BE11468"

record_single() {
  local name="$1"
  local duration="${2:-7}"
  local mp4="$TMP/${name}_demo.mp4"
  local gif="$ASSETS/${name}_demo.gif"
  local palette="$TMP/palette_${name}.png"

  echo "🎬 [1/3] Launching demo: $name on iOS Simulator..."
  cd "$ROOT/example"
  fvm flutter run -d "$UDID" -t lib/demo_auto_player.dart --dart-define="DEMO=$name" &
  local FLUTTER_PID=$!

  # Wait for app to build, attach, and start animating
  echo "⏳ Waiting for app to launch and animate..."
  sleep 15

  echo "🎥 [2/3] Recording $name ($duration s)..."
  xcrun simctl io "$UDID" recordVideo --codec=h264 "$mp4" &
  local REC_PID=$!
  sleep "$duration"
  kill -SIGINT "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true

  # Kill flutter run process
  kill -9 "$FLUTTER_PID" 2>/dev/null || true
  killall -9 Flutter 2>/dev/null || true
  pkill -f "demo_auto_player.dart" 2>/dev/null || true
  sleep 2

  echo "🎨 [3/3] Converting $name to high-resolution GIF..."
  ffmpeg -y -i "$mp4" -vf "scale=400:-1:flags=lanczos,fps=16,palettegen=max_colors=256:reserve_transparent=0" -update 1 "$palette" -loglevel warning
  ffmpeg -y -i "$mp4" -i "$palette" -filter_complex "scale=400:-1:flags=lanczos,fps=16[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -loop 0 "$gif" -loglevel warning

  local size
  size=$(du -sh "$gif" | cut -f1)
  echo "✅ $name.gif generated successfully ($size)"
  echo ""
}

echo "=========================================================="
echo " Starting Full Automated Demo Recording Session"
echo "=========================================================="

DEMOS=(
  "float"
  "ruby"
  "selection"
  "table"
  "comparison"
  "performance"
)

for demo in "${DEMOS[@]}"; do
  record_single "$demo" 7
done

echo "🎉 ALL 6 DEMO GIFS HAVE BEEN RECORDED & CONVERTED!"
