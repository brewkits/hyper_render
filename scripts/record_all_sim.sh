#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/assets"
TMP="$ROOT/.demo_recordings"
mkdir -p "$TMP" "$ASSETS"

UDID="52415E8D-5DC0-421F-A5B2-F08E6BE11468"

record_and_convert() {
  local name="$1"
  local duration="$2"
  local mp4="$TMP/${name}.mp4"
  local gif="$ASSETS/${name}.gif"
  local palette="$TMP/palette_${name}.png"

  echo "🎥 Recording $name ($duration s)..."
  xcrun simctl io "$UDID" recordVideo --codec=h264 "$mp4" &
  local PID=$!
  sleep "$duration"
  kill -SIGINT "$PID" 2>/dev/null || true
  wait "$PID" 2>/dev/null || true
  sleep 1

  echo "🎨 Converting $name to optimized GIF..."
  ffmpeg -y -i "$mp4" -vf "scale=360:-1:flags=lanczos,fps=15,palettegen=max_colors=256" -update 1 "$palette" -loglevel warning
  ffmpeg -y -i "$mp4" -i "$palette" -filter_complex "scale=360:-1:flags=lanczos,fps=15[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -loop 0 "$gif" -loglevel warning
  
  local size
  size=$(du -sh "$gif" | cut -f1)
  echo "✅ $name.gif created ($size)"
}

echo "🎬 Starting Demo Recording Batch..."
record_and_convert "float_demo" 8
record_and_convert "ruby_demo" 8
record_and_convert "selection_demo" 8
record_and_convert "table_demo" 8
record_and_convert "comparison_demo" 8
record_and_convert "performance_demo" 8

echo "🎉 All 6 GIFs recorded and converted successfully!"
