#!/bin/sh
# Simple test script - replaces Makefile test target
set -e

echo "🧪 Running basic tests..."

# Test 1: Syntax check
echo "📋 Testing syntax..."
if bash -n ai-switch.sh; then
    echo "✅ Syntax check passed"
else
    echo "❌ Syntax check failed"
    exit 1
fi

# Test 2: Basic functionality
echo "📋 Testing basic functionality..."
TEST_HOME="./test-temp-$$"
mkdir -p "$TEST_HOME/.ai-profiles"
cp ai-switch.sh "$TEST_HOME/.ai-switch.sh"

# Test profile creation
echo 'export TEST_VAR=test_value' > "$TEST_HOME/.ai-profiles/test-profile"

# Test basic script syntax and structure
if HOME="$TEST_HOME" bash -n "$TEST_HOME/.ai-switch.sh"; then
    echo "✅ Basic functionality test passed"
else
    echo "❌ Basic functionality test failed"
    exit 1
fi

# Test profile removal
HOME="$TEST_HOME" bash -c '. "$HOME/.ai-switch.sh"; ai remove test-profile'
if [ -f "$TEST_HOME/.ai-profiles/test-profile" ]; then
    echo "❌ Remove profile test failed"
    exit 1
else
    echo "✅ Remove profile test passed"
fi

# Cleanup
rm -rf "$TEST_HOME"

echo "🎉 All tests passed!"
