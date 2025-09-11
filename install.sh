#!/usr/bin/env bash
# Main install script with remote download capability
set -eu

PREFIX="${PREFIX:-$HOME}"
TARGET="$PREFIX/.ai-switch.sh"
RC_FILE="${AI_RC_FILE:-}"
AI_PROFILES_DIR="${AI_PROFILES_DIR:-$HOME/.ai-profiles}"
AI_INSTALL_TEMPLATES="${AI_INSTALL_TEMPLATES:-1}"

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
REPO_URL="${REPO_URL:-Cactusinhand/ai-switch}"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "https://raw.githubusercontent.com/$REPO_URL/main/ai-switch.sh" -o "$TARGET" || {
    echo "Error: Failed to download ai-switch.sh" >&2
    exit 1
  }
else
  wget -q "https://raw.githubusercontent.com/$REPO_URL/main/ai-switch.sh" -O "$TARGET" || {
    echo "Error: Failed to download ai-switch.sh" >&2
    exit 1
  }
fi

chmod 644 "$TARGET"

# Wire into rc
if [ -z "$RC_FILE" ]; then
  if [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/zsh" ]; then RC_FILE="$HOME/.zshrc"; else RC_FILE="$HOME/.bashrc"; fi
fi
pattern="source \"\$HOME/.ai-switch.sh\""
line="[ -f \"\$HOME/.ai-switch.sh\" ] && source \"\$HOME/.ai-switch.sh\""
if ! grep -q "$pattern" "$RC_FILE" 2>/dev/null; then
  printf '\n# ai-switch\n%s\n' "$line" >>"$RC_FILE"
fi

echo "Installed to $TARGET"
echo "Added source line to $RC_FILE"
echo "Open a new shell or run: source $RC_FILE"

# Seed example profiles only if directory is empty (first install)
if [ "$AI_INSTALL_TEMPLATES" != "0" ]; then
  mkdir -p "$AI_PROFILES_DIR"
  if [ -z "$(ls -A "$AI_PROFILES_DIR" 2>/dev/null)" ]; then
    # Known example templates in repo
    templates=(deepseek glm kimi qwen)
    raw_base="https://raw.githubusercontent.com/$REPO_URL/main/examples/profiles"
    for name in "${templates[@]}"; do
      dst="$AI_PROFILES_DIR/$name"
      if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$raw_base/$name" -o "$dst" || true
      else
        wget -q "$raw_base/$name" -O "$dst" || true
      fi
      # ensure newline at end and sane perms only if download succeeded
      if [ -s "$dst" ]; then
        printf '\n' >> "$dst" 2>/dev/null || true
        chmod 644 "$dst" 2>/dev/null || true
      else
        rm -f "$dst" 2>/dev/null || true
      fi
    done
    echo "Seeded example profiles into $AI_PROFILES_DIR (first install)"
  else
    echo "Profiles dir not empty; skipping template seeding"
  fi
fi
