#!/usr/bin/env bash
# record_showcase_gifs.sh
#
# Records 6 showcase GIFs for HyperRender's README.
# Requires: Xcode (xcrun simctl), ffmpeg
#
# Usage:
#   bash scripts/record_showcase_gifs.sh           # record all 6
#   bash scripts/record_showcase_gifs.sh float ruby # record specific ones
#
# Valid names: float  ruby  selection  table  comparison  performance

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
ASSETS_DIR="$(cd "$(dirname "$0")/.." && pwd)/assets"
TMP_DIR="$(mktemp -d)"
FPS=12
WIDTH=360            # output GIF width (height auto)
QUALITY_SCALE=5      # bayer dither scale 0-5 (5 = best quality, larger file)

# ---------------------------------------------------------------------------
# Check dependencies
# ---------------------------------------------------------------------------
if ! command -v ffmpeg &>/dev/null; then
  echo "❌  ffmpeg not found. Install via: brew install ffmpeg"
  exit 1
fi
if ! command -v xcrun &>/dev/null; then
  echo "❌  xcrun not found. Install Xcode Command Line Tools."
  exit 1
fi

# ---------------------------------------------------------------------------
# Detect booted iOS Simulator
# ---------------------------------------------------------------------------
DEVICE_ID=$(xcrun simctl list devices booted --json 2>/dev/null \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
for runtime,devs in data['devices'].items():
    for d in devs:
        if d['state']=='Booted':
            print(d['udid'])
            exit()
" 2>/dev/null || true)

if [ -z "$DEVICE_ID" ]; then
  echo "❌  No booted iOS Simulator found."
  echo "    Open Xcode → Xcode menu → Open Developer Tool → Simulator"
  echo "    or: xcrun simctl boot <device-udid>"
  exit 1
fi

DEVICE_NAME=$(xcrun simctl list devices booted 2>/dev/null | grep "$DEVICE_ID" | sed 's/ (.*//' | xargs)
echo "✅  Simulator: $DEVICE_NAME ($DEVICE_ID)"
echo ""

# ---------------------------------------------------------------------------
# Determine which demos to record
# ---------------------------------------------------------------------------
ALL_DEMOS=(float ruby selection table comparison performance)

if [ "$#" -gt 0 ]; then
  DEMOS=("$@")
else
  DEMOS=("${ALL_DEMOS[@]}")
fi

# Validate names
for name in "${DEMOS[@]}"; do
  valid=false
  for a in "${ALL_DEMOS[@]}"; do
    [[ "$name" == "$a" ]] && valid=true && break
  done
  if ! $valid; then
    echo "❌  Unknown demo name: '$name'"
    echo "    Valid: ${ALL_DEMOS[*]}"
    exit 1
  fi
done

echo "📋  Will record: ${DEMOS[*]}"
echo ""

# ---------------------------------------------------------------------------
# Helper: record one GIF
# ---------------------------------------------------------------------------
record_demo() {
  local name="$1"      # e.g. "float"
  local label="$2"     # human label
  local instructions="$3"  # what to do in the app

  local out_gif="$ASSETS_DIR/${name}_demo.gif"
  local tmp_mp4="$TMP_DIR/${name}.mp4"
  local palette="$TMP_DIR/${name}_palette.png"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎬  [$name]  $label"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📱  In the app:"
  echo "$instructions" | sed 's/^/    /'
  echo ""
  echo "    Press ENTER when the correct screen is visible and ready."
  read -r

  # Remove stale MP4 if present (broken from previous aborted run)
  rm -f "$tmp_mp4"

  echo "🔴  Recording... press ENTER to stop."
  xcrun simctl io "$DEVICE_ID" recordVideo --codec=h264 --force "$tmp_mp4" &
  REC_PID=$!

  read -r

  # SIGINT — only signal that triggers graceful MP4 finalization (writes moov atom)
  kill -INT "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true

  # Wait until file size stabilises (moov atom written)
  echo "⏳  Finalising MP4..."
  local prev_size=0 cur_size=0
  for _ in {1..20}; do
    sleep 0.5
    cur_size=$(stat -f%z "$tmp_mp4" 2>/dev/null || echo 0)
    [ "$cur_size" -gt 0 ] && [ "$cur_size" -eq "$prev_size" ] && break
    prev_size=$cur_size
  done

  if [ ! -s "$tmp_mp4" ]; then
    echo "❌  MP4 is empty. Try again."
    return 1
  fi

  echo "🎨  Converting to GIF (two-pass palette, auto-compress < 3 MB)..."

  local MAX_BYTES=$(( 3 * 1024 * 1024 ))
  local cur_fps=$FPS
  local cur_width=$WIDTH
  local attempt=0

  while true; do
    attempt=$(( attempt + 1 ))
    echo "    attempt $attempt — ${cur_fps}fps / ${cur_width}px wide"

    # Pass 1 — generate optimal palette
    ffmpeg -y -i "$tmp_mp4" \
      -vf "fps=${cur_fps},scale=${cur_width}:-1:flags=lanczos,palettegen=stats_mode=diff" \
      -update 1 "$palette" -loglevel warning

    # Pass 2 — render GIF using that palette
    ffmpeg -y -i "$tmp_mp4" -i "$palette" \
      -lavfi "fps=${cur_fps},scale=${cur_width}:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=${QUALITY_SCALE}" \
      "$out_gif" -loglevel warning

    local size_bytes
    size_bytes=$(stat -f%z "$out_gif")
    local size_kb=$(( size_bytes / 1024 ))

    if [ "$size_bytes" -le "$MAX_BYTES" ]; then
      echo "✅  Saved: $out_gif (${size_kb} KB)"
      echo ""
      break
    fi

    echo "    ⚠️  ${size_kb} KB > 3 MB — reducing..."

    # Reduce FPS first (12→10→8), then width (360→300→240→180)
    if [ "$cur_fps" -gt 8 ]; then
      cur_fps=$(( cur_fps - 2 ))
    elif [ "$cur_width" -gt 180 ]; then
      cur_width=$(( cur_width - 60 ))
      cur_fps=$FPS   # reset fps when stepping down width
    else
      echo "    ⚠️  Cannot compress further. Saved at ${size_kb} KB."
      echo ""
      break
    fi
  done
}

# ---------------------------------------------------------------------------
# Demo definitions
# ---------------------------------------------------------------------------
for demo in "${DEMOS[@]}"; do
  case "$demo" in

    float)
      record_demo "float" "CSS Float — Magazine Layout" \
"1. From Home, tap 'Float Layout'.
2. Scroll slowly so text wrapping around the image is visible.
3. Pause ~1s, then scroll back up, then down again to show it working."
      ;;

    ruby)
      record_demo "ruby" "Japanese Ruby / Furigana" \
"1. From Home, tap 'Ruby Annotation (振り仮名)'.
2. Scroll through the examples: basic furigana, pinyin, poetry.
3. Tap a few elements if any are interactive."
      ;;

    selection)
      record_demo "selection" "Text Selection Across Paragraphs" \
"1. From Home, tap 'Enhanced Selection Menu ⭐'.
2. Long-press on a word to start selection.
3. Drag the handles to extend selection across multiple paragraphs.
4. Show the context menu (Copy / Share / etc.)."
      ;;

    table)
      record_demo "table" "Advanced Tables" \
"1. From Home, tap 'Advanced Tables ⭐'.
2. Scroll through to show: nested table, financial report, rowspan/colspan.
3. Slow, deliberate scrolling looks better than fast scrolling."
      ;;

    comparison)
      record_demo "comparison" "HyperRender vs FWFH Comparison" \
"1. From Home, tap 'FWFH Issues Test' (or the comparison demo).
2. Show side-by-side rendering where FWFH breaks (float, ruby, selection).
3. Scroll through to highlight the differences."
      ;;

    performance)
      record_demo "performance" "Virtualized Mode / Large Document" \
"1. From Home, tap 'Kitchen Sink' or 'Real Content'.
2. Scroll rapidly up and down through a long document.
3. Show smooth, jank-free scrolling on a large document."
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
rm -rf "$TMP_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉  Done! GIFs saved to: $ASSETS_DIR"
echo ""
echo "Next step — commit:"
echo "  git add assets/*.gif"
echo "  git commit --amend --no-edit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
