#!/usr/bin/env bash
#
# setup-git-ssh.sh — Configure git identity + SSH key for GitHub
# Usage: chmod +x setup-git-ssh.sh && ./setup-git-ssh.sh
#
# Idempotent: safe to re-run, skips anything already configured.
# Also configures SSH to route github.com over port 443, which bypasses
# networks that block outbound port 22 (e.g. institutional Wi-Fi, NAT64 setups).

set -euo pipefail

info()  { echo -e "\033[1;34m[INFO]\033[0m $1"; }
ok()    { echo -e "\033[1;32m[ OK ]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# ---------- 1. Git identity ----------
CURRENT_NAME="$(git config --global user.name || true)"
CURRENT_EMAIL="$(git config --global user.email || true)"

if [[ -n "$CURRENT_NAME" && -n "$CURRENT_EMAIL" ]]; then
  ok "Git identity already set: $CURRENT_NAME <$CURRENT_EMAIL>"
else
  info "Setting up git identity..."
  read -rp "Git user.name: " GIT_NAME
  read -rp "Git user.email: " GIT_EMAIL
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  ok "Git identity set: $GIT_NAME <$GIT_EMAIL>"
fi

# Sensible global defaults (safe to re-run, just overwrites same values)
git config --global init.defaultBranch main
git config --global pull.rebase false

# ---------- 2. SSH key ----------
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_CONFIG="$HOME/.ssh/config"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$SSH_KEY" ]]; then
  ok "SSH key already exists at $SSH_KEY"
else
  info "No SSH key found, generating one..."
  EMAIL="$(git config --global user.email)"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY"
fi

# Start agent + add key to macOS keychain
eval "$(ssh-agent -s)" >/dev/null
ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY"

# ---------- 3. SSH config — route GitHub over port 443 ----------
# Bypasses networks that block outbound port 22 (institutional Wi-Fi, NAT64, etc.)
if ! grep -q "Hostname ssh.github.com" "$SSH_CONFIG" 2>/dev/null; then
  info "Configuring SSH to route github.com over port 443..."
  cat >> "$SSH_CONFIG" << EOF

Host github.com
  Hostname ssh.github.com
  Port 443
  User git
  IdentityFile $SSH_KEY
  UseKeychain yes
  AddKeysToAgent yes
EOF
  chmod 600 "$SSH_CONFIG"
else
  ok "SSH already configured for github.com over port 443"
fi

# ---------- 4. Test GitHub auth ----------
info "Testing GitHub SSH authentication..."
if ssh -T git@github.com -o StrictHostKeyChecking=accept-new 2>&1 | grep -q "successfully authenticated"; then
  ok "GitHub SSH authentication working"
else
  warn "GitHub SSH auth not confirmed — your key likely isn't added to GitHub yet."
  echo ""
  echo "Your public key (copy this to https://github.com/settings/keys):"
  echo "--------------------------------------------------------------"
  cat "${SSH_KEY}.pub"
  echo "--------------------------------------------------------------"
  if command -v pbcopy &>/dev/null; then
    pbcopy < "${SSH_KEY}.pub"
    echo "(also copied to your clipboard)"
  fi
  echo ""
  echo "After adding it on GitHub, re-run this script to confirm."
fi

echo ""
echo "=================================================="
echo " Git + SSH setup complete."
echo "=================================================="
echo "Name:  $(git config --global user.name)"
echo "Email: $(git config --global user.email)"