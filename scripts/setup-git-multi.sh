#!/usr/bin/env bash
#
# setup-git-multi.sh — Configure SEPARATE SSH keys + git identities
#                       for personal and organisational GitHub accounts.
#
# Usage: chmod +x setup-git-multi.sh && ./setup-git-multi.sh
#
# Idempotent: safe to re-run, skips anything already configured.
#
# IMPORTANT — how this actually works:
#   `git clone` has no native "-personal" / "-org" flag. Instead, this script
#   sets up SSH HOST ALIASES. You clone using a fake hostname instead of
#   github.com, and SSH silently uses the right key based on that alias:
#
#     git clone git@github.com-personal:yourname/repo.git   -> uses personal key
#     git clone git@github.com-org:yourorg/repo.git          -> uses org key
#
#   Both aliases route over port 443 (bypasses networks that block port 22).

set -euo pipefail

info()  { echo -e "\033[1;34m[INFO]\033[0m $1"; }
ok()    { echo -e "\033[1;32m[ OK ]\033[0m $1"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $1"; }

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
PERSONAL_KEY="$SSH_DIR/id_ed25519_personal"
ORG_KEY="$SSH_DIR/id_ed25519_org"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ---------- 1. Collect emails ----------
echo "Setting up two GitHub identities: personal and organisational."
echo ""

if [[ -f "$PERSONAL_KEY" ]]; then
  ok "Personal SSH key already exists — skipping email prompt for it"
else
  read -rp "Personal GitHub email: " PERSONAL_EMAIL
fi

if [[ -f "$ORG_KEY" ]]; then
  ok "Org SSH key already exists — skipping email prompt for it"
else
  read -rp "Organisational GitHub email: " ORG_EMAIL
fi

# ---------- 2. Generate SSH keys ----------
if [[ -f "$PERSONAL_KEY" ]]; then
  ok "Personal key already exists at $PERSONAL_KEY"
else
  info "Generating personal SSH key..."
  ssh-keygen -t ed25519 -C "$PERSONAL_EMAIL" -f "$PERSONAL_KEY"
fi

if [[ -f "$ORG_KEY" ]]; then
  ok "Org key already exists at $ORG_KEY"
else
  info "Generating org SSH key..."
  ssh-keygen -t ed25519 -C "$ORG_EMAIL" -f "$ORG_KEY"
fi

# ---------- 3. Add both keys to agent + keychain ----------
eval "$(ssh-agent -s)" >/dev/null
ssh-add --apple-use-keychain "$PERSONAL_KEY" 2>/dev/null || ssh-add "$PERSONAL_KEY"
ssh-add --apple-use-keychain "$ORG_KEY" 2>/dev/null || ssh-add "$ORG_KEY"

# ---------- 4. SSH config with two host aliases (both over port 443) ----------
if ! grep -q "Host github.com-personal" "$SSH_CONFIG" 2>/dev/null; then
  info "Adding github.com-personal alias to SSH config..."
  cat >> "$SSH_CONFIG" << EOF

Host github.com-personal
  Hostname ssh.github.com
  Port 443
  User git
  IdentityFile $PERSONAL_KEY
  IdentitiesOnly yes
  UseKeychain yes
  AddKeysToAgent yes
EOF
else
  ok "github.com-personal alias already configured"
fi

if ! grep -q "Host github.com-org" "$SSH_CONFIG" 2>/dev/null; then
  info "Adding github.com-org alias to SSH config..."
  cat >> "$SSH_CONFIG" << EOF

Host github.com-org
  Hostname ssh.github.com
  Port 443
  User git
  IdentityFile $ORG_KEY
  IdentitiesOnly yes
  UseKeychain yes
  AddKeysToAgent yes
EOF
else
  ok "github.com-org alias already configured"
fi

chmod 600 "$SSH_CONFIG"

# ---------- 5. Directory-based git identity switching ----------
# Any repo cloned under ~/work/** automatically uses your org name/email.
# Everything else falls back to your personal identity (set separately via
# setup-git-ssh.sh or `git config --global user.name/email`).
WORK_DIR="$HOME/work"
GIT_ORG_CONFIG="$HOME/.gitconfig-org"

mkdir -p "$WORK_DIR"

if [[ ! -f "$GIT_ORG_CONFIG" ]]; then
  info "Creating $GIT_ORG_CONFIG for org-specific git identity..."
  ORG_EMAIL_FOR_CONFIG="${ORG_EMAIL:-$(git config --get user.email || echo "")}"
  read -rp "Org git user.name (e.g. Dhileep-TCC): " ORG_GIT_NAME
  cat > "$GIT_ORG_CONFIG" << EOF
[user]
  name = $ORG_GIT_NAME
  email = $ORG_EMAIL_FOR_CONFIG
EOF
else
  ok "$GIT_ORG_CONFIG already exists"
fi

GLOBAL_GITCONFIG="$HOME/.gitconfig"
if ! grep -q "gitdir:$WORK_DIR/" "$GLOBAL_GITCONFIG" 2>/dev/null; then
  info "Wiring up conditional include for $WORK_DIR/ in ~/.gitconfig..."
  cat >> "$GLOBAL_GITCONFIG" << EOF

[includeIf "gitdir:$WORK_DIR/"]
  path = $GIT_ORG_CONFIG
EOF
else
  ok "Conditional include for $WORK_DIR/ already set up"
fi

# ---------- 6. Print public keys for GitHub registration ----------
echo ""
echo "=================================================="
echo " Setup complete. Two identities configured:"
echo "=================================================="
echo ""
echo "PERSONAL public key (add to your PERSONAL GitHub account):"
echo "--------------------------------------------------------------"
cat "${PERSONAL_KEY}.pub"
echo "--------------------------------------------------------------"
echo ""
echo "ORG public key (add to your ORG/work GitHub account):"
echo "--------------------------------------------------------------"
cat "${ORG_KEY}.pub"
echo "--------------------------------------------------------------"
echo ""
echo "Add each key at: https://github.com/settings/keys (on the correct account)"
echo ""
echo "USAGE — how to clone with the right identity:"
echo "  Personal repo: git clone git@github.com-personal:username/repo.git"
echo "  Org repo:       git clone git@github.com-org:orgname/repo.git"
echo ""
echo "Any repo cloned into $WORK_DIR/ automatically uses your org git name/email."
echo "Everything else uses your personal (global) git name/email."