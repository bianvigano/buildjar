#!/usr/bin/env bash
# buildjar/lib/presets.sh — Save/load/list presets

if [[ -z "${BUILDJAR_LIB:-}" ]]; then
  BUILDJAR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$BUILDJAR_LIB/utils.sh"
fi

PRESET_DIR="${PRESET_DIR:-$HOME/.local/share/buildjar}"

load_preset() {
  local pfile="$PRESET_DIR/$1"
  if [[ ! -f "$pfile" ]]; then
    die "Preset '$1' not found. Use --list to see available presets."
  fi
  info "Loading preset: $1"
  # shellcheck disable=SC1090
  source "$pfile"
}

save_preset() {
  local pfile="$PRESET_DIR/$1"
  mkdir -p "$PRESET_DIR"
  echo "# buildjar preset: $1 — $(date)" > "$pfile"
  echo "# cd to project dir then: buildjar $1" >> "$pfile"
  [[ -n "${INSTALL_DIR:-}" ]] && echo "INSTALL_DIR='$INSTALL_DIR'" >> "$pfile"
  [[ -n "${OUT_DIR:-}" ]]     && echo "OUT_DIR='$OUT_DIR'" >> "$pfile"
  [[ -n "${PUSH_TARGET:-}" ]] && echo "PUSH_TARGET='$PUSH_TARGET'" >> "$pfile"
  [[ -n "${TASK:-}" ]]        && echo "TASK='$TASK'" >> "$pfile"
  [[ -n "${PROFILE:-}" ]]     && echo "PROFILE='$PROFILE'" >> "$pfile"
  ${SCAN:-false}           && echo "SCAN=true" >> "$pfile"
  ${THIN:-false}           && echo "THIN=true" >> "$pfile"
  ${CLEAN:-false}          && echo "CLEAN=true" >> "$pfile"
  ${NO_DAEMON:-false}      && echo "NO_DAEMON=true" >> "$pfile"
  ${STACKTRACE:-false}     && echo "STACKTRACE=true" >> "$pfile"
  ${QUIET:-false}          && echo "QUIET=true" >> "$pfile"
  ok "Preset saved: $1 → $pfile"
}

list_presets() {
  echo ""
  echo -e "${WHT}${BLD}╔══════════════════════════════════════════╗${NC}"
  echo -e "${WHT}${BLD}║${NC}       ${MAG}${BLD}BUILDJAR PRESETS${NC}"
  echo -e "${WHT}${BLD}╚══════════════════════════════════════════╝${NC}"
  echo ""
  shopt -s nullglob 2>/dev/null || true
  local found=false
  for f in "$PRESET_DIR"/*; do
    [[ -f "$f" ]] || continue
    found=true
    local name; name=$(basename "$f")
    echo -e "  ${GRN}${name}${NC}"
    grep -v '^#' "$f" | head -5 | while IFS= read -r line; do
      echo -e "    ${DIM}$line${NC}"
    done
    echo ""
  done
  shopt -u nullglob 2>/dev/null || true
  if ! $found; then
    echo -e "  ${DIM}(none — save with: buildjar --save <name>)${NC}"
    echo ""
  fi
  echo -e "  ${DIM}Use: buildjar <name>${NC}"
  echo ""
}

load_project_preset() {
  if [[ -f ".buildjar" ]]; then
    info "Loading project preset: .buildjar"
    set -a; source ".buildjar"; set +a
  fi
}
