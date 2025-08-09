#!/usr/bin/env bats

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  cp "$BATS_TEST_DIRNAME/../ai-switch.sh" "$HOME/.ai-switch.sh"
  echo "[ -f \"$HOME/.ai-switch.sh\" ] && source \"$HOME/.ai-switch.sh\"" >"$HOME/.bashrc"
  echo "[ -f \"$HOME/.ai-switch.sh\" ] && source \"$HOME/.ai-switch.sh\"" >"$HOME/.zshrc"
  mkdir -p "$HOME/.ai-profiles"
  echo 'export FOO=bar' >"$HOME/.ai-profiles/demo"
}

@test "switch applies profile and writes rc block" {
  run bash -lc 'source "$HOME/.ai-switch.sh"; ai switch demo; echo "$FOO"'
  [ "$status" -eq 0 ]
  [ "$output" = $'✅ Switched to: demo (current shell active; new shells inherit)\nbar' ]
}

@test "add from kv creates file" {
  run bash -lc 'source "$HOME/.ai-switch.sh"; ai add kvtest A=B C=D; cat "$HOME/.ai-profiles/kvtest"'
  [ "$status" -eq 0 ]
  [[ "$output" == *'export A=B'* ]]
  [[ "$output" == *'export C=D'* ]]
}