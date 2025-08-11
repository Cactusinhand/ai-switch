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

# Ensure listing handles no profiles
if [ -z "$(HOME="$TEST_HOME" bash -c '. "$HOME/.ai-switch.sh"; ai list | sed -n 2p')" ]; then
    echo "✅ Empty list handled"
else
    echo "❌ Empty list not handled"
    exit 1
fi

# Test profile creation
echo 'export TEST_VAR=test_value' > "$TEST_HOME/.ai-profiles/test-profile"

# Ensure listing shows the created profile
if HOME="$TEST_HOME" bash -c '. "$HOME/.ai-switch.sh"; ai list | grep -qx "test-profile"'; then
    echo "✅ List shows profile"
else
    echo "❌ List did not include profile"
    exit 1
fi

# Test basic script syntax and structure
if HOME="$TEST_HOME" bash -n "$TEST_HOME/.ai-switch.sh"; then
    echo "✅ Basic functionality test passed"
else
    echo "❌ Basic functionality test failed"
    exit 1
fi

# Test profile removal (active)
(
    export HOME="$TEST_HOME"
    bash -c '
        . "$HOME/.ai-switch.sh"
        ai switch test-profile
        ai remove test-profile
        if [ -n "${TEST_VAR:-}" ]; then
            echo "❌ Remove profile did not clear vars"
            exit 1
        fi
        if [ -f "$HOME/.ai-profiles/.current" ]; then
            echo "❌ Remove profile did not remove state"
            exit 1
        fi
        if grep -q "AI CONFIG START" "$HOME/.bashrc"; then
            echo "❌ Remove profile did not clean rc file"
            exit 1
        fi
    '
)
if [ -f "$TEST_HOME/.ai-profiles/test-profile" ]; then
    echo "❌ Remove profile test failed"
    exit 1
else
    echo "✅ Remove profile test passed"
fi

# Recreate profile for failure test
echo 'export TEST_VAR=test_value' > "$TEST_HOME/.ai-profiles/test-profile"

# Test profile removal failure when rc update fails
(
    export HOME="$TEST_HOME"
    bash -c '
        . "$HOME/.ai-switch.sh"
        ai switch test-profile
        AI_RC_FILE="/proc/self/mem"
        if ai remove test-profile; then
            echo "❌ Remove should have failed"
            exit 1
        fi
        if [ ! -f "$HOME/.ai-profiles/.current" ]; then
            echo "❌ State file removed on failure"
            exit 1
        fi
        if [ -z "${TEST_VAR:-}" ]; then
            echo "❌ Vars cleared on failure"
            exit 1
        fi
        if ! grep -q "AI CONFIG START" "$HOME/.bashrc"; then
            echo "❌ RC block removed on failure"
            exit 1
        fi
    '
)
if [ ! -f "$TEST_HOME/.ai-profiles/test-profile" ]; then
    echo "❌ Profile file removed on failure"
    exit 1
else
    echo "✅ Remove failure handled correctly"
fi

# Test removing block when rc file is absent
(
    export HOME="$TEST_HOME"
    bash -c '
        . "$HOME/.ai-switch.sh"
        AI_RC_FILE="$HOME/missingrc"
        _ai_remove_block_from_rc
        if [ -f "$HOME/missingrc" ]; then
            echo "❌ RC removal created file"
            exit 1
        fi
    '
)
echo "✅ RC removal without existing file leaves filesystem untouched"

# Cleanup
rm -rf "$TEST_HOME"

echo "🎉 All tests passed!"
