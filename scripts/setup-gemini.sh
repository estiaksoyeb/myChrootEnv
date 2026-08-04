#!/usr/bin/env bash
set -e

echo "==> Updating system"
apt update && apt upgrade -y

echo "==> Installing base tools"
apt install -y curl wget git vim gnupg ca-certificates

echo "==> Purging distro Node.js (if present)"
apt purge -y \
  nodejs libnode* node-acorn node-undici node-busboy \
  node-cjs-module-lexer node-xtend nodejs-doc || true
apt autoremove -y

echo "==> Setting up NodeSource (Node 20)"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | gpg --dearmor --batch --yes -o /etc/apt/keyrings/nodesource.gpg

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] \
https://deb.nodesource.com/node_20.x nodistro main" \
  > /etc/apt/sources.list.d/nodesource.list

apt update
apt install -y nodejs

echo "==> Node versions"
node -v
npm -v

echo "==> Installing Gemini CLI"
npm install -g @google/gemini-cli@latest

echo "==> Fixing PATH for npm globals (root)"
NPM_BIN="$(npm prefix -g)/bin"
if ! echo "$PATH" | grep -q "$NPM_BIN"; then
  echo "export PATH=\"$NPM_BIN:\$PATH\"" >> ~/.bashrc
  export PATH="$NPM_BIN:$PATH"
fi

echo "==> Verifying Gemini"
which gemini
gemini --version

echo "==> DONE. Gemini is ready."
