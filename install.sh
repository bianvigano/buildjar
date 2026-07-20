#!/usr/bin/env bash
# install.sh — One-command installer for buildjar
# Usage: curl -fsSL https://raw.githubusercontent.com/bianvigano/buildjar/main/install.sh | bash

set -Eeuo pipefail

BIN_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/buildjar/lib"
REPO="https://github.com/bianvigano/buildjar.git"
TMP_DIR=$(mktemp -d -t buildjar-install.XXXXXX)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo ""
echo "════════════════════════════════════════════"
echo "  buildjar installer"
echo "════════════════════════════════════════════"
echo ""

# Check sudo
if [[ $EUID -ne 0 ]] && ! command -v sudo &>/dev/null; then
  echo "✗ Need root. Run: sudo bash install.sh"
  exit 1
fi
SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

# Check Java
if ! command -v java &>/dev/null; then
  echo "! Java not found. buildjar requires JDK. Install:"
  echo "  sudo apt install openjdk-21-jdk"
  echo ""
fi

echo "→ Cloning $REPO..."
git clone --depth 1 "$REPO" "$TMP_DIR" 2>/dev/null || {
  echo "✗ Clone failed. Trying with HTTPS..."
  git clone --depth 1 "https://github.com/bianvigano/buildjar.git" "$TMP_DIR"
}

echo "→ Installing to $BIN_DIR and $LIB_DIR..."
$SUDO mkdir -p "$LIB_DIR"
$SUDO cp "$TMP_DIR/buildjar/buildjar" "$BIN_DIR/buildjar"
$SUDO cp "$TMP_DIR/buildjar/lib/"*.sh "$LIB_DIR/"
$SUDO chmod +x "$BIN_DIR/buildjar"
$SUDO chmod -R 755 "$(dirname "$LIB_DIR")"

echo ""
echo "✓ buildjar installed!"
echo ""
echo "  Try: buildjar --help"
echo ""
echo "  Optional aliases (add to ~/.bash_aliases):"
echo "    alias bikinjar='buildjar'"
echo ""

# Auto-add alias if bash_aliases exists
if [[ -f "$HOME/.bash_aliases" ]]; then
  if ! grep -q "alias bikinjar" "$HOME/.bash_aliases" 2>/dev/null; then
    echo "alias bikinjar='buildjar'" >> "$HOME/.bash_aliases"
    echo "  ✓ Added 'bikinjar' alias to ~/.bash_aliases"
    echo "  Run: source ~/.bashrc"
    echo ""
  fi
fi

echo "  For --watch mode: sudo apt install inotify-tools"
echo ""
