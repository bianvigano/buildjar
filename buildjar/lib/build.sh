#!/usr/bin/env bash
# buildjar/lib/build.sh — Gradle/Maven build engine

if [[ -z "${BUILDJAR_LIB:-}" ]]; then
  BUILDJAR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$BUILDJAR_LIB/utils.sh"
  source "$BUILDJAR_LIB/detect.sh"
fi

# ── Find Output JAR ─────────────────────────────────────
find_output_jar() {
  local jar=""
  if $HAS_GRADLE; then
    jar=$(find build/libs -maxdepth 1 -name "*.jar" ! -name "*-sources.jar" ! -name "*-javadoc.jar" \
      -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    [[ -z "$jar" ]] && jar=$(find build -maxdepth 1 -name "*.jar" ! -name "*-sources.jar" ! -name "*-javadoc.jar" \
      -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  else
    jar=$(find target -maxdepth 1 -name "*.jar" ! -name "*-sources.jar" ! -name "*-javadoc.jar" ! -name "original-*.jar" \
      -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  fi
  echo "$jar"
}

# ── Post-build Summary ──────────────────────────────────
post_summary() {
  local exit_code=$1
  local elapsed=$(($(date +%s) - START_TIME))

  if [[ $exit_code -ne 0 ]]; then
    err "Build FAILED after ${elapsed}s"
    return $exit_code
  fi

  local jar
  jar=$(find_output_jar)

  if [[ -z "$jar" ]]; then
    warn "Build OK but no JAR found."
    warn "Searched: build/libs/ or target/"
    echo ""
    info "Listing build output:"
    if $HAS_GRADLE; then
      find build -name "*.jar" 2>/dev/null || echo "  (none)"
    else
      find target -name "*.jar" 2>/dev/null || echo "  (none)"
    fi
    return 0
  fi

  local size
  size=$(du -h "$jar" 2>/dev/null | cut -f1 || echo "?")

  ok "Build done in ${elapsed}s"
  echo ""
  echo "  $(basename "$jar")  ${size}"
  echo "  $(realpath "$jar" 2>/dev/null || echo "$PROJECT_DIR/$jar")"

  [[ -n "${OUT_DIR:-}" ]] && {
    mkdir -p "$OUT_DIR"
    cp "$jar" "$OUT_DIR/"
    ok "Copied to $OUT_DIR/$(basename "$jar")"
  }

  [[ -n "${INSTALL_DIR:-}" ]] && {
    mkdir -p "$INSTALL_DIR"
    cp "$jar" "$INSTALL_DIR/"
    ok "Installed to $INSTALL_DIR/$(basename "$jar")"
  }
}

# ── Gradle Build ────────────────────────────────────────
build_gradle() {
  if [[ -x "./gradlew" ]]; then
    GRADLE="./gradlew"
  elif command -v gradle &>/dev/null; then
    GRADLE="gradle"
  else
    die "gradlew not found and 'gradle' not in PATH."
  fi

  local gradle_args=()

  ${CLEAN:-false}       && gradle_args+=("clean")
  ${NO_DAEMON:-false}   && gradle_args+=("--no-daemon")
  ${STACKTRACE:-false}  && gradle_args+=("--stacktrace")
  ${VERBOSE:-false}     && gradle_args+=("--info")
  [[ -n "${PROFILE:-}" ]] && gradle_args+=("-P$PROFILE")

  if [[ -n "${TASK:-}" ]]; then
    gradle_args+=("$TASK")
  elif ${THIN:-false}; then
    gradle_args+=("jar")
  else
    local dt; dt=$(detect_mod_task)
    if [[ -n "$dt" ]]; then
      gradle_args+=("$dt")
    else
      gradle_args+=("shadowJar")
    fi
  fi

  echo ""
  info "Running: $GRADLE ${gradle_args[*]}"
  echo ""

  if ${DRY_RUN:-false}; then
    ok "Dry run — not building."
    return 0
  fi

  $GRADLE "${gradle_args[@]}"
  return $?
}

# ── Maven Build ─────────────────────────────────────────
build_maven() {
  if ! command -v mvn &>/dev/null; then
    die "mvn not found in PATH."
  fi

  local mvn_args=()

  ${CLEAN:-false}       && mvn_args+=("clean")
  ${STACKTRACE:-false}  && mvn_args+=("-e")
  ${VERBOSE:-false}     && mvn_args+=("-X")
  ${NO_DAEMON:-false}   && mvn_args+=("--no-transfer-progress")
  [[ -n "${PROFILE:-}" ]] && mvn_args+=("-P$PROFILE")

  if [[ -n "${TASK:-}" ]]; then
    mvn_args+=("$TASK")
  elif ${THIN:-false}; then
    mvn_args+=("package")
  else
    mvn_args+=("package" "assembly:single")
  fi

  mvn_args+=("-DskipTests")

  echo ""
  info "Running: mvn ${mvn_args[*]}"
  echo ""

  if ${DRY_RUN:-false}; then
    ok "Dry run — not building."
    return 0
  fi

  mvn "${mvn_args[@]}"
  return $?
}

# ── Do Build (shared entry) ─────────────────────────────
do_build() {
  if $HAS_GRADLE; then
    build_gradle
  else
    build_maven
  fi
  post_summary $?
}
