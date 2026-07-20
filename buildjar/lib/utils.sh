#!/usr/bin/env bash
# buildjar/lib/utils.sh — Colors, logging helpers
# Source this first in all modules.

set -Eeuo pipefail

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
CYA='\033[0;36m'; MAG='\033[0;35m'; WHT='\033[1;37m'; NC='\033[0m'
BLD='\033[1m'; DIM='\033[2m'

ok()   { echo -e "${GRN}[✓]${NC} $*"; }
warn() { echo -e "${YLW}[!]${NC} $*" >&2; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }
info() { echo -e "${CYA}[•]${NC} $*"; }
lbl()  { echo -e "  ${DIM}$1:${NC} ${BLD}$2${NC}"; }
die()  { err "$*"; exit 1; }
