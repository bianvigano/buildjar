#!/usr/bin/env bash
# buildjar/lib/extra.sh — Extra features: test, check-updates, push

if [[ -z "${BUILDJAR_LIB:-}" ]]; then
  BUILDJAR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$BUILDJAR_LIB/utils.sh"
  source "$BUILDJAR_LIB/detect.sh"
  source "$BUILDJAR_LIB/build.sh"
fi

# ── Run Tests ──────────────────────────────────────────
run_tests() {
  echo ""
  echo -e "${WHT}${BLD}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${WHT}${BLD}║${NC}  ${MAG}${BLD}🧪 RUNNING TESTS${NC}"
  echo -e "${WHT}${BLD}╚══════════════════════════════════════════════╝${NC}"
  echo ""

  if $HAS_GRADLE; then
    local bt; bt=$(detect_build_tool)
    local args=()
    ${NO_DAEMON:-false}   && args+=("--no-daemon")
    ${STACKTRACE:-false}  && args+=("--stacktrace")

    if ${DRY_RUN:-false}; then
      info "Would run: $bt ${args[*]} test"
    else
      info "Running: $bt ${args[*]} test"
      echo ""
      $bt "${args[@]}" test
    fi
  else
    if ${DRY_RUN:-false}; then
      info "Would run: mvn test"
    else
      info "Running: mvn test"
      echo ""
      mvn test
    fi
  fi
}

# ── Check Dependency Updates ────────────────────────────
check_dependency_updates() {
  echo ""
  echo -e "${WHT}${BLD}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${WHT}${BLD}║${NC}  ${MAG}${BLD}📦 DEPENDENCY CHECK${NC}"
  echo -e "${WHT}${BLD}╚══════════════════════════════════════════════╝${NC}"
  echo ""

  if $HAS_GRADLE; then
    local bt; bt=$(detect_build_tool)
    if ${DRY_RUN:-false}; then
      info "Would run: $bt dependencyUpdates"
    else
      info "Running: $bt dependencyUpdates (this may take a moment)"
      echo ""
      $bt dependencyUpdates 2>&1 || true
    fi
  else
    if ${DRY_RUN:-false}; then
      info "Would run: mvn versions:display-dependency-updates"
    else
      info "Running: mvn versions:display-dependency-updates"
      echo ""
      mvn versions:display-dependency-updates -DprocessDependencyManagement=false 2>&1 || true
    fi
  fi
}

# ── Push to Remote ─────────────────────────────────────
push_jar() {
  local target="$1"
  local jar
  jar=$(find_output_jar)

  if [[ -z "$jar" ]]; then
    warn "No JAR found. Building first..."
    do_build || die "Build failed — cannot push."
    jar=$(find_output_jar)
    [[ -z "$jar" ]] && die "Still no JAR after build."
  fi

  info "Pushing $(basename "$jar") → $target"

  if ${DRY_RUN:-false}; then
    ok "Dry run — would SCP: $jar → $target"
    return 0
  fi

  scp "$jar" "$target" && ok "Pushed: $target/$(basename "$jar")"
  return $?
}
