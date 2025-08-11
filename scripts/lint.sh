#!/bin/sh
# Simple lint script - replaces Makefile lint target
set -e

echo "🔍 Running lint checks..."

# Check for shellcheck if available
if command -v shellcheck >/dev/null 2>&1; then
    echo "📋 Running shellcheck..."
    if shellcheck ai-switch.sh scripts/*.sh; then
        echo "✅ Shellcheck passed"
    else
        echo "❌ Shellcheck found issues"
        exit 1
    fi
else
    echo "⚠️  shellcheck not found, skipping"
fi

# Basic syntax checks
echo "📋 Checking syntax..."
for script in ai-switch.sh scripts/*.sh; do
    if bash -n "$script"; then
        echo "✅ $script: syntax OK"
    else
        echo "❌ $script: syntax error"
        exit 1
    fi
done

echo "🎉 Lint checks completed!"
