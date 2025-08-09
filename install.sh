#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME}"
TARGET="$PREFIX/.ai-switch.sh"
RC_FILE="${AI_RC_FILE:-}"

if [ "${1:-}" = "--uninstall" ]; then
  echo "Uninstalling ai-switch..."
  rm -f "$TARGET"
  # Optional: remove rc include (non-destructive)
  if [ -z "$RC_FILE" ]; then
    if [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/zsh" ]; then RC_FILE="$HOME/.zshrc"; else RC_FILE="$HOME/.bashrc"; fi
  fi
  sed -i.bak "/source \"\$HOME\/\.ai-switch\.sh\"/d" "$RC_FILE" || true
  echo "Done. You may remove AI block manually if desired."
  exit 0
fi

mkdir -p "$(dirname "$TARGET")"

# Fetch ai-switch.sh
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "https://raw.githubusercontent.com/<you>/ai-switch/main/ai-switch.sh" -o "$TARGET"
else
  wget -q "https://raw.githubusercontent.com/<you>/ai-switch/main/ai-switch.sh" -O "$TARGET"
fi

chmod 644 "$TARGET"

# Wire into rc
if [ -z "$RC_FILE" ]; then
  if [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/zsh" ]; then RC_FILE="$HOME/.zshrc"; else RC_FILE="$HOME/.bashrc"; fi
fi
if ! grep -q 'source "$HOME/.ai-switch.sh"' "$RC_FILE" 2>/dev/null; then
  printf '\n# ai-switch\n[ -f "$HOME/.ai-switch.sh" ] && source "$HOME/.ai-switch.sh"\n' >>"$RC_FILE"
fi

echo "Installed to $TARGET"
echo "Added source line to $RC_FILE"
echo "Open a new shell or run: source $RC_FILE"