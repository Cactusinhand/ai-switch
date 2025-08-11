#!/bin/sh
# Simple install script for local development - replaces Makefile
set -e

echo "🚀 Installing ai-switch..."

# Copy main script
cp ai-switch.sh "$HOME/.ai-switch.sh"
chmod 644 "$HOME/.ai-switch.sh"

# Determine shell config file
if [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/zsh" ]; then
    RC_FILE="$HOME/.zshrc"
else
    RC_FILE="$HOME/.bashrc"
fi

# Add source line if not already present
# shellcheck disable=SC2016
SOURCE_LINE='[ -f "$HOME/.ai-switch.sh" ] && source "$HOME/.ai-switch.sh"'
if ! grep -q "source \"\$HOME/.ai-switch.sh\"" "$RC_FILE" 2>/dev/null; then
    printf '\n# ai-switch\n%s\n' "$SOURCE_LINE" >> "$RC_FILE"
    echo "✅ Added to $RC_FILE"
else
    echo "✅ Already configured in $RC_FILE"
fi

echo "🎉 Installation complete!"
echo "📝 Open a new shell or run: source $RC_FILE"
echo "💡 Get started: ai list"
