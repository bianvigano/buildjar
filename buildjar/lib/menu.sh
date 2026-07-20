#!/usr/bin/env bash
# buildjar/lib/menu.sh — Interactive menu

if [[ -z "${BUILDJAR_LIB:-}" ]]; then
  BUILDJAR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$BUILDJAR_LIB/utils.sh"
  source "$BUILDJAR_LIB/detect.sh"
  source "$BUILDJAR_LIB/build.sh"
  source "$BUILDJAR_LIB/scan.sh"
  source "$BUILDJAR_LIB/version.sh"
  source "$BUILDJAR_LIB/watch.sh"
  source "$BUILDJAR_LIB/extra.sh"
fi

show_full_help() {
  echo ""
  echo -e "${WHT}${BLD}buildjar / bikinjar — Universal Java Project Builder${NC}"
  echo ""
  echo -e "${WHT}${BLD}USAGE${NC}"
  echo -e "  buildjar                     Build fat JAR (auto-detect task)"
  echo -e "  buildjar --menu              Interactive menu mode"
  echo -e "  buildjar <preset>            Load saved preset"
  echo ""
  echo -e "${WHT}${BLD}BUILD OPTIONS${NC}"
  echo -e "  --scan          ${DIM}Analyze project without building${NC}"
  echo -e "  --thin          ${DIM}Thin JAR only (no fat/shadow)${NC}"
  echo -e "  --clean         ${DIM}Run clean before build${NC}"
  echo -e "  --no-daemon     ${DIM}Gradle --no-daemon (CI safe)${NC}"
  echo -e "  --stacktrace    ${DIM}Full error trace${NC}"
  echo -e "  --info          ${DIM}Verbose output${NC}"
  echo -e "  --dry-run       ${DIM}Show command, don't run${NC}"
  echo -e "  -q, --quiet     ${DIM}Suppress non-error output${NC}"
  echo -e "  --task NAME     ${DIM}Override build task${NC}"
  echo -e "  --profile NAME  ${DIM}Gradle -P / Maven -P${NC}"
  echo ""
  echo -e "${WHT}${BLD}OUTPUT OPTIONS${NC}"
  echo -e "  -o, --out DIR       ${DIM}Copy JAR to directory${NC}"
  echo -e "  --install DIR       ${DIM}Copy to server plugins/mods${NC}"
  echo -e "  --push USER@HOST:P  ${DIM}Build + SCP to remote${NC}"
  echo ""
  echo -e "${WHT}${BLD}UTILITY MODES${NC}"
  echo -e "  --menu          ${DIM}Interactive menu${NC}"
  echo -e "  --test          ${DIM}Run tests only${NC}"
  echo -e "  --check-updates ${DIM}Show outdated deps${NC}"
  echo -e "  --version TYPE  ${DIM}Bump version: patch|minor|major${NC}"
  echo -e "  --watch         ${DIM}Auto-rebuild on changes${NC}"
  echo -e "  --save NAME     ${DIM}Save flags as preset${NC}"
  echo -e "  --list          ${DIM}List presets${NC}"
  echo ""
  echo -e "${WHT}${BLD}AUTO-DETECT${NC}"
  echo -e "  Fabric/Quilt/Architectury → remapJar"
  echo -e "  NeoForge                  → build"
  echo -e "  Forge                     → jarJar"
  echo -e "  Paper/Spigot/Plugin       → shadowJar"
  echo ""
  echo -e "${WHT}${BLD}ENV OVERRIDES${NC}"
  echo -e "  JAVA_HOME             JDK path"
  echo -e "  BUILDJAR_GRADLE=0     Force Maven"
  echo -e "  BUILDJAR_MAVEN=0      Force Gradle"
  echo ""
  echo -e "${WHT}${BLD}EXAMPLES${NC}"
  echo -e "  buildjar"
  echo -e "  buildjar --install ~/server/plugins --save server1"
  echo -e "  buildjar server1"
  echo -e "  buildjar --push me@vps:/srv/plugins"
  echo -e "  buildjar --watch --install ~/server/plugins"
  echo -e "  buildjar --version patch"
  echo -e "  buildjar --menu"
  echo -e "  buildjar --list"
  echo ""
}

show_menu() {
  set +e
  detect_project_silent
  local v dt bt
  v=$(get_project_version 2>/dev/null) || v=""
  dt=$(detect_mod_task 2>/dev/null) || dt=""
  bt=$(detect_build_tool 2>/dev/null) || bt=""

  while true; do
    clear 2>/dev/null || true
    echo ""
    echo -e "${WHT}${BLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${WHT}${BLD}║${NC}        ${MAG}${BLD}BUILDJAR MENU${NC}"
    echo -e "${WHT}${BLD}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${DIM}Project:${NC} ${BLD}$(basename "$PROJECT_DIR")${NC}"
    if $HAS_GRADLE; then
      echo -e "  ${DIM}System:${NC}  ${GRN}Gradle${NC} ${DIM}($bt)${NC}"
    else
      echo -e "  ${DIM}System:${NC}  ${GRN}Maven${NC}"
    fi
    [[ -n "$v" ]] && echo -e "  ${DIM}Version:${NC} ${YLW}$v${NC}"
    [[ -n "$dt" ]] && echo -e "  ${DIM}Type:${NC}    $(label_mod_task "$dt")"
    echo ""

    echo -e "${WHT}${BLD}── BUILD ──${NC}"
    echo -e "  ${BLD}1${NC}) Build        ${DIM}(fat JAR)${NC}"
    echo -e "  ${BLD}2${NC}) Build Thin   ${DIM}(JAR without deps)${NC}"
    echo -e "  ${BLD}3${NC}) Clean Build  ${DIM}(clean + build)${NC}"
    echo ""
    echo -e "${WHT}${BLD}── ACTIONS ──${NC}"
    echo -e "  ${BLD}4${NC}) Scan         ${DIM}(analyze)${NC}"
    echo -e "  ${BLD}5${NC}) Test         ${DIM}(run tests)${NC}"
    echo -e "  ${BLD}6${NC}) Watch        ${DIM}(auto-rebuild)${NC}"
    echo -e "  ${BLD}7${NC}) Check Updates ${DIM}(deps)${NC}"
    echo ""
    echo -e "${WHT}${BLD}── DEPLOY ──${NC}"
    echo -e "  ${BLD}8${NC}) Install      ${DIM}(build + copy)${NC}"
    echo -e "  ${BLD}9${NC}) Push         ${DIM}(build + SCP)${NC}"
    echo ""
    echo -e "${WHT}${BLD}── OTHER ──${NC}"
    echo -e "  ${BLD}v${NC}) Version Bump"
    echo -e "  ${BLD}s${NC}) Save Preset"
    echo -e "  ${BLD}h${NC}) Help"
    echo -e "  ${BLD}q${NC}) Quit"
    echo ""

    echo -ne "  ${CYA}Choice →${NC} "
    read -r choice

    case "$choice" in
      1) THIN=false; CLEAN=false; do_build; echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      2) THIN=true; CLEAN=false; do_build; echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      3) THIN=false; CLEAN=true; do_build; echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      4) scan_project; echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      5) run_tests; echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      6) watch_loop ;;
      7) check_dependency_updates; echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      8)
        echo -ne "  ${DIM}Install dir (e.g. ~/server/plugins):${NC} "; read -r inst_dir
        [[ -z "$inst_dir" ]] && { warn "No directory."; echo -ne "${DIM}Press Enter...${NC}"; read -r; continue; }
        THIN=false; CLEAN=false; INSTALL_DIR="$inst_dir"; do_build
        echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      9)
        echo -ne "  ${DIM}Push target (user@host:/path):${NC} "; read -r push_tgt
        [[ -z "$push_tgt" ]] && { warn "No target."; echo -ne "${DIM}Press Enter...${NC}"; read -r; continue; }
        THIN=false; CLEAN=false; PUSH_TARGET="$push_tgt"; do_build; push_jar "$push_tgt"
        echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      v|V)
        echo ""; echo -e "  ${DIM}Bump type:${NC}"
        echo -e "  ${BLD}p${NC}) patch  ${DIM}(1.0.0 → 1.0.1)${NC}"
        echo -e "  ${BLD}n${NC}) minor  ${DIM}(1.0.0 → 1.1.0)${NC}"
        echo -e "  ${BLD}m${NC}) major  ${DIM}(1.0.0 → 2.0.0)${NC}"
        echo -ne "  ${CYA}Choice →${NC} "; read -r bc
        case "$bc" in p|P) bump_version "patch" ;; n|N) bump_version "minor" ;; m|M) bump_version "major" ;; *) warn "Invalid." ;; esac
        echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      s|S)
        echo -ne "  ${DIM}Preset name:${NC} "; read -r pname
        [[ -z "$pname" ]] && { warn "No name."; echo -ne "${DIM}Press Enter...${NC}"; read -r; continue; }
        save_preset "$pname"
        echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      h|H) show_full_help; echo ""; echo -ne "${DIM}Press Enter...${NC}"; read -r ;;
      q|Q) echo ""; exit 0 ;;
      *) warn "Invalid: $choice"; sleep 1 ;;
    esac
  done
}
