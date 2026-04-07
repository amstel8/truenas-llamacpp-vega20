#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install.sh — Claude Code + remote llama.cpp (auto-detect model)
# ---------------------------------------------------------------------------

BASE_URL="http://192.168.168.188:11434"

ZSHRC="$HOME/.zshrc"
CLAUDE_SETTINGS_DIR="$HOME/.claude"
CLAUDE_SETTINGS="$CLAUDE_SETTINGS_DIR/settings.json"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${BLUE}[info]${RESET}  $1"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $1"; }
skip()    { echo -e "${YELLOW}[skip]${RESET}  $1"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $1"; }
fail()    { echo -e "${RED}[fail]${RESET}  $1"; exit 1; }
header()  { echo -e "\n${BOLD}$1${RESET}"; }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
header "Preflight checks"

if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "This script is for macOS only."
fi

if ! command -v brew &>/dev/null; then
    fail "Homebrew not found. Install it first: https://brew.sh"
fi

# ---------------------------------------------------------------------------
# Check server availability
# ---------------------------------------------------------------------------
header "Checking remote llama.cpp server"

if ! curl -sf "${BASE_URL}/v1/models" > /dev/null; then
    fail "Cannot reach ${BASE_URL}/v1/models"
fi

ok "Server reachable"

# ---------------------------------------------------------------------------
# Detect model
# ---------------------------------------------------------------------------
header "Detecting model"

MODEL=$(curl -s "${BASE_URL}/v1/models" | \
    grep -o '"id":"[^"]*"' | \
    head -n 1 | \
    cut -d'"' -f4)

if [[ -z "$MODEL" ]]; then
    fail "Could not detect model from ${BASE_URL}/v1/models"
fi

ok "Detected model: ${MODEL}"

# ---------------------------------------------------------------------------
# Node.js
# ---------------------------------------------------------------------------
header "1/3 — Node.js"

if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
    if (( NODE_VERSION >= 18 )); then
        ok "Node.js $(node --version) already installed."
    else
        info "Upgrading Node.js..."
        brew upgrade node
    fi
else
    info "Installing Node.js..."
    brew install node
fi

# ---------------------------------------------------------------------------
# Claude Code
# ---------------------------------------------------------------------------
header "2/3 — Claude Code"

if command -v claude &>/dev/null; then
    ok "Claude Code already installed."
else
    info "Installing Claude Code..."
    brew install --cask claude-code
fi

# ---------------------------------------------------------------------------
# Claude settings
# ---------------------------------------------------------------------------
header "3/3 — Claude settings"

mkdir -p "$CLAUDE_SETTINGS_DIR"

cat > "$CLAUDE_SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "${BASE_URL}",
    "ANTHROPIC_AUTH_TOKEN": "local",
    "ANTHROPIC_MODEL": "${MODEL}",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "128000",
    "DISABLE_PROMPT_CACHING": "1",
    "DISABLE_AUTOUPDATER": "1",
    "DISABLE_TELEMETRY": "1"
  }
}
EOF

ok "Settings written to $CLAUDE_SETTINGS"

# ---------------------------------------------------------------------------
# .zshrc
# ---------------------------------------------------------------------------
header "Shell config"

MARKER="# Claude remote llama.cpp"

if grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    skip ".zshrc already configured."
else
    cat << EOF >> "$ZSHRC"

# Claude remote llama.cpp
export ANTHROPIC_BASE_URL="${BASE_URL}"
export ANTHROPIC_AUTH_TOKEN="local"
export ANTHROPIC_MODEL="${MODEL}"
EOF
    ok "Environment variables added to $ZSHRC"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
header "Done"
echo ""
echo -e "Detected model:"
echo -e "  ${GREEN}${MODEL}${RESET}"
echo ""
echo -e "Now run:"
echo -e "  ${BOLD}source ~/.zshrc${RESET}"
echo -e "  ${BOLD}npx @anthropic-ai/claude-code${RESET}"
echo ""
echo -e "Using remote server:"
echo -e "  ${BOLD}${BASE_URL}${RESET}"
echo ""