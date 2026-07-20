#!/usr/bin/env bash
# buildjar/lib/version.sh — Version bump

if [[ -z "${BUILDJAR_LIB:-}" ]]; then
  BUILDJAR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$BUILDJAR_LIB/utils.sh"
  source "$BUILDJAR_LIB/detect.sh"
fi

bump_version_number() {
  local old="$1" type="$2"
  local major minor patch
  major=$(echo "$old" | cut -d. -f1)
  minor=$(echo "$old" | cut -d. -f2)
  patch=$(echo "$old" | cut -d. -f3)
  case "$type" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    patch) echo "${major}.${minor}.$((patch + 1))" ;;
    *)     echo "$old" ;;
  esac
}

bump_version() {
  local type="${1:-patch}"
  local old_ver new_ver
  old_ver=$(get_project_version)

  if [[ -z "$old_ver" ]]; then
    die "Cannot detect current version. Set version in gradle.properties, build.gradle, or plugin.yml"
  fi

  new_ver=$(bump_version_number "$old_ver" "$type")
  info "Version: $old_ver → ${YLW}$new_ver${NC}"

  if ${DRY_RUN:-false}; then
    ok "Dry run — version not changed."
    return 0
  fi

  local bumped=false

  # gradle.properties
  if [[ -f "gradle.properties" ]] && grep -q "^version" "gradle.properties"; then
    sed -i "s/^version\s*=\s*${old_ver}/version=${new_ver}/" "gradle.properties"
    ok "Updated gradle.properties"
    bumped=true
  fi

  # build.gradle / build.gradle.kts
  for f in build.gradle build.gradle.kts; do
    [[ ! -f "$f" ]] && continue
    if grep -qP "^\s*version\s*[= ]\s*[\"']?${old_ver}" "$f" 2>/dev/null; then
      sed -i "s/^\\(\\s*version\\s*[= ]\\s*[\"']\\?\\)${old_ver}/\\1${new_ver}/" "$f"
      ok "Updated $f"
      bumped=true
      break
    fi
  done

  for f in src/main/resources/plugin.yml src/main/resources/paper-plugin.yml; do
    [[ ! -f "$f" ]] && continue
    if grep -qP "^version:\s*${old_ver}" "$f" 2>/dev/null; then
      sed -i "s/^version:\s*${old_ver}/version: ${new_ver}/" "$f"
      ok "Updated $f"
      bumped=true
    fi
  done

  if ! $bumped; then
    warn "No version field found to bump."
  fi
}
