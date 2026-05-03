#!/usr/bin/env bash
# =============================================================================
# HyperRender Demo GIF Recorder
# =============================================================================
#
# Records all 6 demo clips from the example app and converts them to optimized GIFs.
#
# Requirements:
#   - ffmpeg       (brew install ffmpeg)
#   - iOS Simulator running OR Android device connected via ADB
#   - Example app built and installed on the device/simulator
#
# Usage:
#   # Run full interactive session (step-by-step)
#   ./scripts/record_demos.sh
#
#   # Convert existing videos to GIF only (no new recording)
#   ./scripts/record_demos.sh convert-only
#
#   # Record a specific single demo (float | ruby | selection | table | comparison | performance)
#   ./scripts/record_demos.sh single float
#
# Output: assets/*.gif (replaces old GIFs)
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/assets"
TMP="$ROOT/.demo_recordings"
MODE="${1:-interactive}"
SINGLE_DEMO="${2:-}"

# ── Terminal Colors ─────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC}  $*" >&2; }
success() { echo -e "${GREEN}✓${NC}  $*" >&2; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*" >&2; }
error()   { echo -e "${RED}✗${NC}  $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}" >&2; }

# ── Check for ffmpeg ────────────────────────────────────────────────────────
if ! command -v ffmpeg &>/dev/null; then
  error "ffmpeg not found. Install with: brew install ffmpeg"
fi

# ── Create Temporary Directory ──────────────────────────────────────────────
mkdir -p "$TMP" "$ASSETS"

# =============================================================================
# Demo Configuration
# =============================================================================
# Format: NAME|GIF_FILE|DURATION_SEC|DESCRIPTION|DEMO_SCREEN
declare -a DEMOS=(
  "float|float_demo.gif|12|CSS Float Layout — text wraps around floated images|Float Layout (Highlights → Float Layout)"
  "ruby|ruby_demo.gif|10|Ruby/Furigana CJK typography|Japanese typography (Text & Typography → Japanese & Manga)"
  "selection|selection_demo.gif|12|Crash-free text selection across paragraphs|Text Selection (Text & Typography → Text Selection)"
  "table|table_demo.gif|10|Advanced tables with colspan/rowspan|Tables (Layout → Tables)"
  "comparison|comparison_demo.gif|14|Head-to-head with flutter_html and flutter_widget_from_html|Why HyperRender (Home → Why HyperRender?)"
  "performance|performance_demo.gif|12|Virtualized 60 FPS rendering on long documents|Performance (Performance & Stress → Stress Test)"
)

# ── GIF settings ──────────────────────────────────────────────────────────────
GIF_WIDTH=360       # px — phone portrait width
GIF_FPS=15          # frames per second (15 = smooth, smaller file than 30)
GIF_SCALE="scale=${GIF_WIDTH}:-1:flags=lanczos"

# =============================================================================
# Record from iOS Simulator
# =============================================================================
record_ios() {
  local name="$1"
  local duration="$2"
  local outfile="$TMP/${name}.mp4"

  # Find booted simulator
  local UDID
  UDID=$(xcrun simctl list devices booted -j 2>/dev/null \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
for runtime in d.get('devices', {}).values():
    for dev in runtime:
        if dev.get('state') == 'Booted':
            print(dev['udid'])
            exit()
" 2>/dev/null || true)

  if [[ -z "$UDID" ]]; then
    error "No iOS Simulator running. Please open Simulator and build the example app first."
  fi

  info "Starting iOS Simulator recording (${duration}s)..."
  info "→ Navigate to the demo screen NOW and interact for ${duration}s."
  echo "" >&2

  # Record in background
  xcrun simctl io "$UDID" recordVideo --codec=h264 "$outfile" &
  local REC_PID=$!

  # Countdown
  for ((i=duration; i>0; i--)); do
    printf "\r  ⏺  Recording... ${i}s remaining   " >&2
    sleep 1
  done
  printf "\r  ⏹  Stopping recording...              \n" >&2

  # Stop recording
  kill -SIGINT "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true
  sleep 1

  echo "$outfile"
}

# =============================================================================
# Record from Android (adb)
# =============================================================================
record_android() {
  local name="$1"
  local duration="$2"
  local outfile="$TMP/${name}.mp4"
  local device_path="/sdcard/hyper_${name}.mp4"

  # Check for device
  if ! adb devices | grep -q "device$"; then
    error "No Android device connected. Connect a device and enable USB debugging."
  fi

  info "Starting Android recording (${duration}s)..."
  info "→ Navigate to the demo screen NOW and interact for ${duration}s."
  echo "" >&2

  adb shell screenrecord --time-limit "$duration" "$device_path" &
  local REC_PID=$!

  for ((i=duration; i>0; i--)); do
    printf "\r  ⏺  Recording... ${i}s remaining   " >&2
    sleep 1
  done
  printf "\r  ⏹  Pulling video...              \n" >&2

  wait "$REC_PID" 2>/dev/null || true
  adb pull "$device_path" "$outfile"
  adb shell rm "$device_path"

  echo "$outfile"
}

# =============================================================================
# Convert video → GIF (2-pass palette)
# =============================================================================
convert_to_gif() {
  local video="$1"
  local gif="$2"

  info "Converting → $(basename "$gif") ..."

  # Pass 1: generate optimal palette
  local palette="$TMP/palette_$(basename "$gif" .gif).png"
  ffmpeg -y -i "$video" \
    -vf "${GIF_SCALE},fps=${GIF_FPS},palettegen=max_colors=256:stats_mode=diff" \
    "$palette" -loglevel warning

  # Pass 2: apply palette → GIF
  ffmpeg -y -i "$video" -i "$palette" \
    -filter_complex "${GIF_SCALE},fps=${GIF_FPS}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
    -loop 0 \
    "$gif" -loglevel warning

  local size
  size=$(du -sh "$gif" | cut -f1)
  success "$(basename "$gif") — ${size}"
}

# =============================================================================
# Detect platform
# =============================================================================
detect_platform() {
  if xcrun simctl list devices booted 2>/dev/null | grep -q "Booted"; then
    echo "ios"
  elif adb devices 2>/dev/null | grep -q "device$"; then
    echo "android"
  else
    echo "none"
  fi
}

# =============================================================================
# Record a single demo
# =============================================================================
record_demo() {
  local entry="$1"
  IFS='|' read -r name gif_file duration desc screen <<< "$entry"

  step "Demo: ${BOLD}${desc}"
  echo ""
  echo -e "  ${BOLD}Screen:${NC}   $screen"
  echo -e "  ${BOLD}Output:${NC}   assets/$gif_file"
  echo -e "  ${BOLD}Duration:${NC} ${duration}s"
  echo ""

  local platform
  platform=$(detect_platform)

  if [[ "$platform" == "none" ]]; then
    warn "No iOS Simulator or Android device found."
    warn "Please open Simulator or connect an Android device and try again."
    return 1
  fi

  echo -e "  Platform: ${CYAN}${platform}${NC}"
  echo ""
  echo -e "  ${YELLOW}Preparation:${NC}"
  echo "  1. Open Example app"
  echo "  2. Navigate to: $screen"
  echo "  3. Scroll/swipe to show the main content"
  echo ""
  read -rp "  Press [Enter] when you are ready..."

  local video
  if [[ "$platform" == "ios" ]]; then
    video=$(record_ios "$name" "$duration")
  else
    video=$(record_android "$name" "$duration")
  fi

  convert_to_gif "$video" "$ASSETS/$gif_file"

  echo ""
  echo -e "  ${GREEN}✓ Done! See result:${NC} assets/$gif_file"
}

# =============================================================================
# Convert-only mode
# =============================================================================
convert_only_mode() {
  step "Convert-only mode — searching for videos in $TMP"

  local found=0
  for entry in "${DEMOS[@]}"; do
    IFS='|' read -r name gif_file duration desc screen <<< "$entry"
    local video="$TMP/${name}.mp4"
    if [[ -f "$video" ]]; then
      convert_to_gif "$video" "$ASSETS/$gif_file"
      found=$((found + 1))
    else
      warn "Not found: $video (skipping)"
    fi
  done

  if [[ "$found" -eq 0 ]]; then
    error "No videos found in $TMP. Record some first."
  fi
  success "Converted $found videos → GIF"
}

# =============================================================================
# Main
# =============================================================================
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   HyperRender Demo Recorder v1.3.0       ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

if [[ "$MODE" == "convert-only" ]]; then
  convert_only_mode
  exit 0
fi

if [[ "$MODE" == "single" && -n "$SINGLE_DEMO" ]]; then
  # Single demo mode
  found=0
  for entry in "${DEMOS[@]}"; do
    IFS='|' read -r name gif_file duration desc screen <<< "$entry"
    if [[ "$name" == "$SINGLE_DEMO" ]]; then
      record_demo "$entry"
      found=1
      break
    fi
  done
  if [[ "$found" -eq 0 ]]; then
    error "Demo '$SINGLE_DEMO' does not exist. Choose from: float | ruby | selection | table | comparison | performance"
  fi
  exit 0
fi

# ── Interactive mode (default) ───────────────────────────────────────────────
echo "Will record 6 demo GIFs in order:"
echo ""
for entry in "${DEMOS[@]}"; do
  IFS='|' read -r name gif_file duration desc screen <<< "$entry"
  echo -e "  ${CYAN}[$name]${NC} $desc (${duration}s)"
done
echo ""

platform=$(detect_platform)
if [[ "$platform" == "none" ]]; then
  echo -e "${YELLOW}Preparation Guide:${NC}"
  echo ""
  echo "  iOS Simulator:"
  echo "    open -a Simulator"
  echo "    cd example && flutter run"
  echo ""
  echo "  Android:"
  echo "    cd example && flutter run -d <device-id>"
  echo ""
  error "No device found. Open Simulator or connect Android and try again."
fi

echo -e "  Platform: ${CYAN}${platform}${NC}"
echo ""

# Ask to record all or choose specific
echo "Options:"
echo "  [a] Record all 6 demos in order"
echo "  [s] Select a specific demo"
echo "  [q] Quit"
echo ""
read -rp "Selection [a/s/q]: " choice

case "$choice" in
  a|A)
    for entry in "${DEMOS[@]}"; do
      record_demo "$entry"
      echo ""
    done
    step "Completed!"
    echo ""
    echo "All GIFs created in assets/:"
    for entry in "${DEMOS[@]}"; do
      IFS='|' read -r name gif_file _ _ _ <<< "$entry"
      if [[ -f "$ASSETS/$gif_file" ]]; then
        size=$(du -sh "$ASSETS/$gif_file" | cut -f1)
        echo -e "  ${GREEN}✓${NC} assets/$gif_file  (${size})"
      fi
    done
    ;;

  s|S)
    echo ""
    echo "Select demo:"
    i=1
    for entry in "${DEMOS[@]}"; do
      IFS='|' read -r name gif_file duration desc screen <<< "$entry"
      echo "  [$i] $name — $desc"
      i=$((i+1))
    done
    echo ""
    read -rp "Enter number (1-6): " idx
    idx=$((idx - 1))
    if [[ "$idx" -lt 0 || "$idx" -ge "${#DEMOS[@]}" ]]; then
      error "Invalid selection"
    fi
    record_demo "${DEMOS[$idx]}"
    ;;

  q|Q)
    info "Exiting."
    exit 0
    ;;

  *)
    error "Invalid choice"
    ;;
esac

echo ""
echo -e "${BOLD}${GREEN}✓ Done! GIFs are ready to be committed and pushed to GitHub.${NC}"
echo ""
echo "  git add assets/*.gif assets/logo.svg"
echo "  git commit -m 'assets: update demo GIFs v1.3.0'"
echo "  git push"
echo ""
