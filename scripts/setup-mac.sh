#!/usr/bin/env bash
#
# setup-mac.sh — Bootstrap a fresh macOS dev environment
# Usage: chmod +x setup-mac.sh && ./setup-mac.sh
#
# Idempotent: safe to re-run, skips anything already installed.

set -euo pipefail

# ---------- helpers ----------
info()  { echo -e "\033[1;34m[INFO]\033[0m $1"; }
ok()    { echo -e "\033[1;32m[ OK ]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $1"; }

SHELL_CONFIG="$HOME/.zshrc"
PROFILE_CONFIG="$HOME/.zprofile"

# ---------- 1. Xcode Command Line Tools ----------
if xcode-select -p &>/dev/null; then
  ok "Xcode Command Line Tools already installed"
else
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Press ENTER once the CLT install dialog finishes..."
  read -r
fi

# ---------- 2. Homebrew ----------
if command -v brew &>/dev/null; then
  ok "Homebrew already installed"
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for this script AND persisted for future shells
BREW_SHELLENV='eval "$(/opt/homebrew/bin/brew shellenv zsh)"'
if ! grep -qF "$BREW_SHELLENV" "$PROFILE_CONFIG" 2>/dev/null; then
  echo "$BREW_SHELLENV" >> "$PROFILE_CONFIG"
  info "Added Homebrew to PATH in $PROFILE_CONFIG"
fi
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# ---------- 3. git ----------
if brew list git &>/dev/null; then
  ok "git already installed via brew"
else
  info "Installing git..."
  brew install git
fi
git --version

# ---------- 4. Python ----------
if brew list python@3.14 &>/dev/null; then
  ok "python@3.14 already installed via brew"
else
  info "Installing python..."
  brew install python
fi
python3 --version

# ---------- 5. fnm (Node version manager) ----------
if command -v fnm &>/dev/null; then
  ok "fnm already installed"
else
  info "Installing fnm..."
  brew install fnm
fi

FNM_LINE='eval "$(fnm env --use-on-cd)"'
if ! grep -qF "$FNM_LINE" "$PROFILE_CONFIG" 2>/dev/null; then
  echo "$FNM_LINE" >> "$PROFILE_CONFIG"
  info "Added fnm shell hook to $PROFILE_CONFIG"
fi
eval "$(fnm env --use-on-cd)"

if fnm list | grep -q "lts"; then
  ok "Node LTS already installed via fnm"
else
  info "Installing Node LTS..."
  fnm install --lts
fi
fnm use lts-latest
fnm default "$(node -v | sed 's/v//' | cut -d. -f1)"
node -v
npm -v

# ---------- 6. Bun ----------
if command -v bun &>/dev/null; then
  ok "Bun already installed"
else
  info "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
fi

BUN_LINE_1='export BUN_INSTALL="$HOME/.bun"'
BUN_LINE_2='export PATH="$BUN_INSTALL/bin:$PATH"'
if ! grep -qF "$BUN_LINE_1" "$SHELL_CONFIG" 2>/dev/null; then
  echo "$BUN_LINE_1" >> "$SHELL_CONFIG"
  echo "$BUN_LINE_2" >> "$SHELL_CONFIG"
  info "Added Bun to PATH in $SHELL_CONFIG"
fi
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun --version

# ---------- 7. Google Antigravity IDE (AI-first code editor) ----------
if brew list --cask antigravity-ide &>/dev/null; then
  ok "Google Antigravity IDE already installed"
else
  info "Installing Google Antigravity IDE..."
  brew install --cask antigravity-ide
fi

# ---------- Summary ----------
echo ""
echo "=================================================="
echo " Setup complete. Installed versions:"
echo "=================================================="
echo "git:    $(git --version)"
echo "python: $(python3 --version)"
echo "node:   $(node -v)"
echo "npm:    $(npm -v)"
echo "bun:    $(bun --version)"
echo "antigravity-ide: $(brew list --cask antigravity-ide &>/dev/null && echo 'installed' || echo 'not installed')"
echo ""
warn "Open a NEW terminal tab (or run: source ~/.zprofile && source ~/.zshrc) to load all PATH changes cleanly."