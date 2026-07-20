#!/usr/bin/env bash
# buildjar/lib/watch.sh — File watch + auto-rebuild

if [[ -z "${BUILDJAR_LIB:-}" ]]; then
  BUILDJAR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$BUILDJAR_LIB/utils.sh"
  source "$BUILDJAR_LIB/build.sh"
fi

watch_loop() {
  if ! command -v inotifywait &>/dev/null; then
    die "inotifywait not found. Install: sudo apt install inotify-tools"
  fi

  local watch_dirs=()
  [[ -d "src" ]] && watch_dirs+=("src")
  [[ -f "build.gradle" ]] && watch_dirs+=("build.gradle")
  [[ -f "build.gradle.kts" ]] && watch_dirs+=("build.gradle.kts")
  [[ -f "pom.xml" ]] && watch_dirs+=("pom.xml")
  [[ -f "settings.gradle" ]] && watch_dirs+=("settings.gradle")

  if [[ ${#watch_dirs[@]} -eq 0 ]]; then
    die "No source directories or build files to watch."
  fi

  ok "Watching: ${watch_dirs[*]}"
  echo "  Save a file to trigger rebuild. Ctrl+C to stop."
  echo ""

  do_build

  while true; do
    inotifywait -q -e modify,create,delete,move -r "${watch_dirs[@]}" --exclude '(build/|target/|\.gradle/|node_modules/)' 2>/dev/null
    echo ""
    echo -e "${CYA}───────────────────────────────────────────────${NC}"
    info "File changed — rebuilding..."
    echo -e "${CYA}───────────────────────────────────────────────${NC}"
    do_build || true
  done
}
