#!/usr/bin/env bash
# =============================================================================
# HyperRender Demo GIF Recorder
# =============================================================================
#
# Ghi lại tất cả 6 demo clips từ example app và convert thành GIF tối ưu.
#
# Yêu cầu:
#   - ffmpeg       (brew install ffmpeg)
#   - iOS Simulator đang chạy HOẶC Android device kết nối qua ADB
#   - Example app đã được build và cài sẵn trên device/simulator
#
# Cách dùng:
#   # Chạy toàn bộ (hướng dẫn từng bước)
#   ./scripts/record_demos.sh
#
#   # Chỉ convert video có sẵn → GIF (không record mới)
#   ./scripts/record_demos.sh convert-only
#
#   # Record 1 demo cụ thể (float | ruby | selection | table | comparison | performance)
#   ./scripts/record_demos.sh single float
#
# Output: assets/*.gif  (thay thế GIFs cũ)
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/assets"
TMP="$ROOT/.demo_recordings"
MODE="${1:-interactive}"
SINGLE_DEMO="${2:-}"

# ── Màu terminal ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
success() { echo -e "${GREEN}✓${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}✗${NC}  $*"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

# ── Kiểm tra ffmpeg ───────────────────────────────────────────────────────────
if ! command -v ffmpeg &>/dev/null; then
  error "ffmpeg không tìm thấy. Cài đặt: brew install ffmpeg"
fi

# ── Tạo thư mục tạm ──────────────────────────────────────────────────────────
mkdir -p "$TMP" "$ASSETS"

# =============================================================================
# Cấu hình từng demo
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
# Record từ iOS Simulator
# =============================================================================
record_ios() {
  local name="$1"
  local duration="$2"
  local outfile="$TMP/${name}.mp4"

  # Tìm booted simulator
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
    error "Không có iOS Simulator nào đang chạy. Mở Simulator rồi build example app trước."
  fi

  info "Bắt đầu record iOS Simulator (${duration}s)..."
  info "→ Điều hướng đến màn hình demo BÂY GIỜ, rồi tương tác trong ${duration}s."
  echo ""

  # Record trong background
  xcrun simctl io "$UDID" recordVideo --codec=h264 "$outfile" &
  local REC_PID=$!

  # Countdown
  for ((i=duration; i>0; i--)); do
    printf "\r  ⏺  Recording... ${i}s còn lại   "
    sleep 1
  done
  printf "\r  ⏹  Dừng recording...              \n"

  # Stop recording
  kill -SIGINT "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true
  sleep 1

  echo "$outfile"
}

# =============================================================================
# Record từ Android (adb)
# =============================================================================
record_android() {
  local name="$1"
  local duration="$2"
  local outfile="$TMP/${name}.mp4"
  local device_path="/sdcard/hyper_${name}.mp4"

  # Kiểm tra device
  if ! adb devices | grep -q "device$"; then
    error "Không có Android device nào kết nối. Kết nối device và bật USB debugging."
  fi

  info "Bắt đầu record Android (${duration}s)..."
  info "→ Điều hướng đến màn hình demo BÂY GIỜ, rồi tương tác trong ${duration}s."
  echo ""

  adb shell screenrecord --time-limit "$duration" "$device_path" &
  local REC_PID=$!

  for ((i=duration; i>0; i--)); do
    printf "\r  ⏺  Recording... ${i}s còn lại   "
    sleep 1
  done
  printf "\r  ⏹  Pulling video...              \n"

  wait "$REC_PID" 2>/dev/null || true
  adb pull "$device_path" "$outfile"
  adb shell rm "$device_path"

  echo "$outfile"
}

# =============================================================================
# Convert video → GIF tối ưu (2-pass palette)
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
# Record một demo
# =============================================================================
record_demo() {
  local entry="$1"
  IFS='|' read -r name gif_file duration desc screen <<< "$entry"

  step "Demo: ${BOLD}${desc}"
  echo ""
  echo -e "  ${BOLD}Màn hình:${NC} $screen"
  echo -e "  ${BOLD}Output:${NC}   assets/$gif_file"
  echo -e "  ${BOLD}Thời gian:${NC} ${duration}s"
  echo ""

  local platform
  platform=$(detect_platform)

  if [[ "$platform" == "none" ]]; then
    warn "Không tìm thấy iOS Simulator hoặc Android device."
    warn "Mở Simulator hoặc kết nối Android rồi chạy lại."
    return 1
  fi

  echo -e "  Platform: ${CYAN}${platform}${NC}"
  echo ""
  echo -e "  ${YELLOW}Chuẩn bị:${NC}"
  echo "  1. Mở Example app"
  echo "  2. Điều hướng đến: $screen"
  echo "  3. Scroll/vuốt để thấy nội dung chính"
  echo ""
  read -rp "  Nhấn [Enter] khi bạn đã sẵn sàng..."

  local video
  if [[ "$platform" == "ios" ]]; then
    video=$(record_ios "$name" "$duration")
  else
    video=$(record_android "$name" "$duration")
  fi

  convert_to_gif "$video" "$ASSETS/$gif_file"

  echo ""
  echo -e "  ${GREEN}✓ Xong! Xem kết quả:${NC} assets/$gif_file"
}

# =============================================================================
# Convert-only mode (video đã có sẵn trong .demo_recordings/)
# =============================================================================
convert_only_mode() {
  step "Convert-only mode — tìm video trong $TMP"

  local found=0
  for entry in "${DEMOS[@]}"; do
    IFS='|' read -r name gif_file duration desc screen <<< "$entry"
    local video="$TMP/${name}.mp4"
    if [[ -f "$video" ]]; then
      convert_to_gif "$video" "$ASSETS/$gif_file"
      found=$((found + 1))
    else
      warn "Không tìm thấy: $video (bỏ qua)"
    fi
  done

  if [[ "$found" -eq 0 ]]; then
    error "Không có video nào trong $TMP. Hãy record trước."
  fi
  success "Đã convert $found video → GIF"
}

# =============================================================================
# Main
# =============================================================================
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   HyperRender Demo Recorder v1.1.4       ║${NC}"
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
    error "Demo '$SINGLE_DEMO' không tồn tại. Chọn: float | ruby | selection | table | comparison | performance"
  fi
  exit 0
fi

# ── Interactive mode (mặc định) ───────────────────────────────────────────────
echo "Sẽ record 6 demo GIFs theo thứ tự:"
echo ""
for entry in "${DEMOS[@]}"; do
  IFS='|' read -r name gif_file duration desc screen <<< "$entry"
  echo -e "  ${CYAN}[$name]${NC} $desc (${duration}s)"
done
echo ""

platform=$(detect_platform)
if [[ "$platform" == "none" ]]; then
  echo -e "${YELLOW}Hướng dẫn chuẩn bị:${NC}"
  echo ""
  echo "  iOS Simulator:"
  echo "    open -a Simulator"
  echo "    cd example && flutter run"
  echo ""
  echo "  Android:"
  echo "    cd example && flutter run -d <device-id>"
  echo ""
  error "Không tìm thấy device. Mở Simulator hoặc kết nối Android rồi chạy lại."
fi

echo -e "  Platform: ${CYAN}${platform}${NC}"
echo ""

# Hỏi có muốn record tất cả hay chọn từng cái
echo "Tùy chọn:"
echo "  [a] Record tất cả 6 demos theo thứ tự"
echo "  [s] Chọn demo cụ thể"
echo "  [q] Thoát"
echo ""
read -rp "Chọn [a/s/q]: " choice

case "$choice" in
  a|A)
    for entry in "${DEMOS[@]}"; do
      record_demo "$entry"
      echo ""
    done
    step "Hoàn thành!"
    echo ""
    echo "Tất cả GIFs đã được tạo trong assets/:"
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
    echo "Chọn demo:"
    i=1
    for entry in "${DEMOS[@]}"; do
      IFS='|' read -r name gif_file duration desc screen <<< "$entry"
      echo "  [$i] $name — $desc"
      i=$((i+1))
    done
    echo ""
    read -rp "Nhập số (1-6): " idx
    idx=$((idx - 1))
    if [[ "$idx" -lt 0 || "$idx" -ge "${#DEMOS[@]}" ]]; then
      error "Số không hợp lệ"
    fi
    record_demo "${DEMOS[$idx]}"
    ;;

  q|Q)
    info "Đã thoát."
    exit 0
    ;;

  *)
    error "Lựa chọn không hợp lệ"
    ;;
esac

echo ""
echo -e "${BOLD}${GREEN}✓ Xong! Các GIFs đã sẵn sàng để commit và push lên GitHub.${NC}"
echo ""
echo "  git add assets/*.gif assets/logo.svg"
echo "  git commit -m 'assets: update demo GIFs v1.1.4'"
echo "  git push"
echo ""
