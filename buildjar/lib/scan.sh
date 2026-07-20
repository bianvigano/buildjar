#!/usr/bin/env bash
# buildjar/lib/scan.sh — Project scan/analysis

if [[ -z "${BUILDJAR_LIB:-}" ]]; then
  BUILDJAR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$BUILDJAR_LIB/utils.sh"
  source "$BUILDJAR_LIB/detect.sh"
fi

scan_project() {
  echo ""
  echo -e "${WHT}${BLD}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${WHT}${BLD}║${NC}  ${MAG}${BLD}🔍 BUILDJAR SCAN${NC}"
  echo -e "${WHT}${BLD}╚══════════════════════════════════════════════╝${NC}"
  echo ""

  lbl "Project"  "$(basename "$PROJECT_DIR")"
  lbl "Path"     "$PROJECT_DIR"
  echo ""

  # Build system
  echo -e "${WHT}${BLD}── Build System${NC}"
  if $HAS_GRADLE; then
    lbl "System" "Gradle"
    [[ -f "build.gradle" ]]     && lbl "Config"  "build.gradle"
    [[ -f "build.gradle.kts" ]] && lbl "Config"  "build.gradle.kts"
    [[ -f "settings.gradle" || -f "settings.gradle.kts" ]] && lbl "Settings" "yes"
    if [[ -x "./gradlew" ]]; then
      local gw_ver
      gw_ver=$(./gradlew --version 2>/dev/null | grep 'Gradle ' | head -1 | awk '{print $2}' || echo "?")
      lbl "Wrapper" "./gradlew (Gradle $gw_ver)"
    elif command -v gradle &>/dev/null; then
      lbl "Wrapper" "none (using system gradle)"
    else
      warn "No gradlew or system gradle found"
    fi
  else
    lbl "System" "Maven"
    lbl "Config" "pom.xml"
    command -v mvn &>/dev/null && lbl "Binary" "$(command -v mvn)" || warn "mvn not found"
  fi
  echo ""

  # Version
  local v; v=$(get_project_version 2>/dev/null) || v=""
  [[ -n "$v" ]] && echo -e "${WHT}${BLD}── Version${NC}" && lbl "Current" "$v" && echo ""

  # Dependencies
  if $HAS_GRADLE; then
    echo -e "${WHT}${BLD}── Dependencies${NC}"
    for f in build.gradle build.gradle.kts; do
      [[ ! -f "$f" ]] && continue
      local dep_count
      dep_count=$(grep -cE '(implementation|api|compileOnly|runtimeOnly|modImplementation|modCompileOnly|modRuntimeOnly|shadow)\b.*:.*:' "$f" 2>/dev/null || echo 0)
      lbl "Count"   "$dep_count deps"
      grep -nE '(implementation|api|compileOnly|runtimeOnly|modImplementation|modCompileOnly|modRuntimeOnly|shadow)\b' "$f" 2>/dev/null | \
        sed "s/^[[:space:]]*//" | while IFS= read -r line; do
        echo -e "  ${DIM}$line${NC}"
      done
      break
    done
    echo ""
  fi

  # Plugins
  if $HAS_GRADLE; then
    echo -e "${WHT}${BLD}── Plugins${NC}"
    for f in build.gradle build.gradle.kts; do
      [[ ! -f "$f" ]] && continue
      grep -nE '^\s*(id|kotlin|application|java)' "$f" 2>/dev/null | \
        sed "s/^[[:space:]]*//" | while IFS= read -r line; do
        echo -e "  ${DIM}$line${NC}"
      done
      break
    done
    echo ""
  fi

  # Mod loader
  local detected; detected=$(detect_mod_task)
  echo -e "${WHT}${BLD}── Project Type${NC}"
  if [[ -n "$detected" ]]; then
    lbl "Loader" "$(label_mod_task "$detected")"
    lbl "Task"   "$detected"
  elif $HAS_GRADLE; then
    if grep -q 'com.gradleup.shadow' build.gradle build.gradle.kts 2>/dev/null; then
      lbl "Type"  "Plugin (shadowJar)"
      lbl "Task"  "shadowJar"
    elif grep -qE 'paper|spigot|bukkit' build.gradle build.gradle.kts 2>/dev/null; then
      lbl "Type"  "Paper/Spigot Plugin"
      lbl "Task"  "shadowJar"
    else
      lbl "Type"  "Standard Java"
      lbl "Task"  "shadowJar (default)"
    fi
  else
    lbl "Type"  "Standard Java (Maven)"
    lbl "Task"  "package assembly:single"
  fi
  echo ""

  # Java version
  echo -e "${WHT}${BLD}── Java${NC}"
  lbl "Runtime"  "$(java -version 2>&1 | head -1)"
  if $HAS_GRADLE; then
    for f in build.gradle build.gradle.kts; do
      [[ ! -f "$f" ]] && continue
      local jv
      jv=$(grep -oP 'JavaLanguageVersion\.of\(\K\d+' "$f" 2>/dev/null || echo "")
      [[ -z "$jv" ]] && jv=$(grep -oP 'sourceCompatibility\s*=\s*\K\d+' "$f" 2>/dev/null || echo "")
      [[ -z "$jv" ]] && jv=$(grep -oP "release\s*=\s*\K\d+" "$f" 2>/dev/null || echo "")
      [[ -n "$jv" ]] && lbl "Target" "Java $jv"
      break
    done
  fi
  echo ""

  # Source structure
  echo -e "${WHT}${BLD}── Source Structure${NC}"
  local src_dirs=()
  for d in src/main/java src/main/kotlin src/main/resources src/test/java; do
    [[ -d "$d" ]] && src_dirs+=("$d")
  done
  if [[ ${#src_dirs[@]} -gt 0 ]]; then
    for d in "${src_dirs[@]}"; do
      local count; count=$(find "$d" -type f 2>/dev/null | wc -l)
      lbl "  $d" "$count files"
    done
  else
    warn "No standard src/main/java found"
  fi
  echo ""

  # Build artifacts
  if [[ -d "build/libs" ]] || [[ -d "target" ]]; then
    echo -e "${WHT}${BLD}── Existing Build${NC}"
    shopt -s nullglob 2>/dev/null || true
    for f in build/libs/*.jar target/*.jar; do
      [[ -f "$f" ]] || continue
      [[ "$f" == *"-sources.jar" ]] && continue
      [[ "$f" == *"-javadoc.jar" ]] && continue
      local sz; sz=$(du -h "$f" 2>/dev/null | cut -f1)
      echo -e "  ${GRN}$(basename "$f")${NC}  ${DIM}${sz}${NC}"
    done
    shopt -u nullglob 2>/dev/null || true
    echo ""
  fi

  # Command preview
  local cmd_task="${TASK:-}"
  [[ -z "$cmd_task" ]] && cmd_task=$(detect_mod_task)
  [[ -z "$cmd_task" ]] && cmd_task="shadowJar"

  echo -e "${WHT}${BLD}── Build Command${NC}"
  if $HAS_GRADLE; then
    local bt; bt=$(detect_build_tool)
    ${CLEAN:-false} && cmd_task="clean $cmd_task"
    echo -e "  ${CYA}${BLD}$bt $cmd_task${NC}"
    [[ -n "${OUT_DIR:-}" ]]     && echo -e "  ${DIM}→ output to $OUT_DIR${NC}"
    [[ -n "${INSTALL_DIR:-}" ]] && echo -e "  ${DIM}→ install to $INSTALL_DIR${NC}"
    [[ -n "${PUSH_TARGET:-}" ]] && echo -e "  ${DIM}→ push to $PUSH_TARGET${NC}"
  else
    ${CLEAN:-false} && cmd_task="clean $cmd_task"
    echo -e "  ${CYA}${BLD}mvn $cmd_task -DskipTests${NC}"
  fi

  echo ""
  echo -e "${DIM}Run without --scan to build.${NC}"
  echo ""
}
