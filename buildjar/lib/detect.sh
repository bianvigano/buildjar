#!/usr/bin/env bash
# buildjar/lib/detect.sh — Project detection, mod loader, build tool, version

if [[ -z "${BUILDJAR_LIB:-}" ]]; then
  BUILDJAR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$BUILDJAR_LIB/utils.sh"
fi

# ── Project Detection ───────────────────────────────────
detect_project() {
  HAS_GRADLE=false; HAS_MAVEN=false

  [[ -f "build.gradle" || -f "build.gradle.kts" || -f "settings.gradle" || -f "settings.gradle.kts" ]] && HAS_GRADLE=true
  [[ -f "pom.xml" ]] && HAS_MAVEN=true

  [[ "${BUILDJAR_GRADLE:-}" == "0" ]] && HAS_GRADLE=false
  [[ "${BUILDJAR_MAVEN:-}" == "0" ]] && HAS_MAVEN=false

  if $HAS_GRADLE && $HAS_MAVEN; then
    warn "Both Gradle and Maven found — using Gradle"
    warn "Override: BUILDJAR_GRADLE=0 or BUILDJAR_MAVEN=0"
    echo ""
  fi

  if ! $HAS_GRADLE && ! $HAS_MAVEN; then
    die "No build.gradle(.kts) or pom.xml found in $PROJECT_DIR"
  fi
}

detect_project_silent() {
  HAS_GRADLE=false; HAS_MAVEN=false
  [[ -f "build.gradle" || -f "build.gradle.kts" || -f "settings.gradle" || -f "settings.gradle.kts" ]] && HAS_GRADLE=true
  [[ -f "pom.xml" ]] && HAS_MAVEN=true
  [[ "${BUILDJAR_GRADLE:-}" == "0" ]] && HAS_GRADLE=false
  [[ "${BUILDJAR_MAVEN:-}" == "0" ]] && HAS_MAVEN=false
}

# ── Detect Mod Loader ────────────────────────────────────
detect_mod_task() {
  for f in build.gradle build.gradle.kts; do
    [[ ! -f "$f" ]] && continue
    if grep -qE 'fabric-loom|quilt-loom|architectury-plugin|architectury-loom' "$f" 2>/dev/null; then
      echo "remapJar"; return 0
    fi
    if grep -qE 'net\.neoforged\.gradle|neogradle|net\.neoforged\.moddev' "$f" 2>/dev/null; then
      echo "build"; return 0
    fi
    if grep -qE 'net\.minecraftforge\.gradle|forge\.gradle' "$f" 2>/dev/null; then
      echo "jarJar"; return 0
    fi
  done
  echo ""
}

label_mod_task() {
  case "$1" in
    remapJar)  echo "Fabric / Quilt / Architectury" ;;
    jarJar)    echo "Forge (MinecraftForge)" ;;
    build)     echo "NeoForge" ;;
    shadowJar) echo "Paper / Spigot / Plugin" ;;
    *)         echo "custom ($1)" ;;
  esac
}

detect_build_tool() {
  if $HAS_GRADLE; then
    if [[ -x "./gradlew" ]]; then echo "./gradlew"
    elif command -v gradle &>/dev/null; then echo "gradle"
    else echo "(missing)"; fi
  else
    if command -v mvn &>/dev/null; then echo "mvn"
    else echo "(missing)"; fi
  fi
}

# ── Get Project Version ─────────────────────────────────
get_project_version() {
  local ver=""
  if [[ -f "gradle.properties" ]]; then
    ver=$(grep -oP '^version\s*=\s*\K.+' "gradle.properties" 2>/dev/null | head -1 | tr -d ' ')
    [[ -n "$ver" ]] && { echo "$ver"; return 0; }
  fi
  for f in build.gradle build.gradle.kts; do
    [[ ! -f "$f" ]] && continue
    ver=$(grep -oP '^\s*version\s*[= ]\s*["'"'"']?\K[0-9][^"'"'"'${IFS}]*' "$f" 2>/dev/null | head -1 || echo "")
    [[ -n "$ver" ]] && { echo "$ver"; return 0; }
  done
  for f in src/main/resources/plugin.yml src/main/resources/paper-plugin.yml; do
    [[ ! -f "$f" ]] && continue
    ver=$(grep -oP '^version:\s*\K.*' "$f" 2>/dev/null | head -1 || echo "")
    [[ -n "$ver" ]] && { echo "$ver"; return 0; }
  done
  echo ""
}

# ── Java Health Check ───────────────────────────────────
check_java() {
  local java_home="${JAVA_HOME:-}"
  local java_cmd="java"
  [[ -n "$java_home" ]] && java_cmd="$java_home/bin/java"

  if ! command -v "$java_cmd" &>/dev/null; then
    die "Java not found. Set JAVA_HOME or install JDK."
  fi

  local ver
  ver=$("$java_cmd" -version 2>&1 | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
  info "Java: $ver ($java_cmd)"

  local javac_cmd="${java_home:+$java_home/bin/}javac"
  if ! command -v "$javac_cmd" &>/dev/null; then
    die "javac not found. Need JDK (not just JRE)."
  fi
}
