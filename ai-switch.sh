# shellcheck shell=bash
# === AI profile switcher (instant apply, with `ai add`) ===
# Version: 0.1.1
# Description: Instantly switch AI provider environment profiles in your shell
# Usage:
#   source "$HOME/.ai-switch.sh"  # typically from ~/.bashrc or ~/.zshrc
#   ai list | ai current | ai switch <name> | ai add <name> [opts] | ai remove <name> | ai edit <name> | ai doctor
#
# Features:
# - Clean, portable export-only profiles
# - Instant profile switching with immediate environment updates
# - Automatic new shell inheritance
# - Template-based profile creation
# - Fzf integration for profile selection
#
# Project: https://github.com/Cactusinhand/ai-switch

# ------ config ------
export AI_PROFILES_DIR="${AI_PROFILES_DIR:-$HOME/.ai-profiles}"
export AI_PROFILE_STATE="${AI_PROFILE_STATE:-$AI_PROFILES_DIR/.current}"
export AI_RC_START="${AI_RC_START:-# >>> AI CONFIG START >>>}"
export AI_RC_END="${AI_RC_END:-# <<< AI CONFIG END <<<}"

# pick rc file by shell; allow override via env
if [ -z "${AI_RC_FILE:-}" ]; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    export AI_RC_FILE="$HOME/.zshrc"
  else
    export AI_RC_FILE="$HOME/.bashrc"
  fi
fi

mkdir -p "$AI_PROFILES_DIR"

# ------ helpers ------

# List all available profiles in the profiles directory
# Returns: List of profile names, one per line
_ai_list_profiles() {
  find "$AI_PROFILES_DIR" -maxdepth 1 -type f ! -name '.current' -printf '%f\n' 2>/dev/null || true
}

# Display the currently active profile
# Returns: Profile name or "(none)" if no profile is active
_ai_current() {
  if [ -f "$AI_PROFILE_STATE" ]; then cat "$AI_PROFILE_STATE"; else echo "(none)"; fi
}

# Extract environment variable names from the AI config block in rc file
# Returns: List of variable names, one per line
_ai_extract_vars_from_block() {
  awk -v s="$AI_RC_START" -v e="$AI_RC_END" '
    $0~s{inblk=1;next} $0~e{inblk=0;next}
    inblk && $0 ~ /^[[:space:]]*export[[:space:]]+[A-Za-z_][A-Za-z0-9_]*=/ {
      match($0,/export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=/,m);
      if (m[1] != "") print m[1];
    }
  ' "$AI_RC_FILE" 2>/dev/null
}

_ai_write_block_to_rc() {
  # $1: profile file path
  _ai_remove_block_from_rc || return 1
  {
    echo "$AI_RC_START"
    cat "$1"
    echo "$AI_RC_END"
  } >>"$AI_RC_FILE" || {
    echo "Error: Failed to write AI config block" >&2
    return 1
  }
}

_ai_remove_block_from_rc() {
  local tmp
  tmp="$(mktemp)" || {
    echo "Error: Failed to create temporary file" >&2
    return 1
  }
  if [ -f "$AI_RC_FILE" ]; then
    cp "$AI_RC_FILE" "${AI_RC_FILE}.bak.$(date +%Y%m%d%H%M%S)" || {
      echo "Warning: Failed to create backup" >&2
    }
    awk -v s="$AI_RC_START" -v e="$AI_RC_END" '
      $0==s{inblk=1; next}
      $0==e{inblk=0; next}
      !inblk{print}
    ' "$AI_RC_FILE" >"$tmp" || {
      echo "Error: Failed to process rc file" >&2
      rm -f "$tmp"
      return 1
    }
  else
    : >"$tmp"
  fi
  mv "$tmp" "$AI_RC_FILE" || {
    echo "Error: Failed to update rc file" >&2
    rm -f "$tmp"
    return 1
  }
}

_ai_source_profile_now() {
  # $1: profile file path
  local v
  for v in $(_ai_extract_vars_from_block); do unset "$v"; done
  set -a
  # shellcheck disable=SC1090
  . "$1"
  set +a
}

_ai_validate_name() {
  # Validate profile name: alphanumeric, hyphens, underscores only
  # Cannot be empty or start with hyphen
  case "$1" in
    "") 
      echo "Error: Profile name cannot be empty" >&2
      return 1 
      ;;
    -*) 
      echo "Error: Profile name cannot start with hyphen" >&2
      return 1 
      ;;
    *[!a-zA-Z0-9_-]*) 
      echo "Error: Profile name contains invalid characters. Use only letters, numbers, hyphens, and underscores" >&2
      return 1 
      ;;
    *) 
      return 0 
      ;;
  esac
}

_ai_profile_path() { echo "$AI_PROFILES_DIR/$1"; }

_ai_write_profile_from_kv() {
  local out="$1"; shift
  : >"$out"
  local kv
  for kv in "$@"; do
    if [[ $kv =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      printf 'export %s\n' "$kv" >>"$out"
    else
      printf 'Ignored invalid: %s\n' "$kv" >&2
    fi
  done
}

_ai_template() {
  cat <<'EOF'
# Add your exports below, e.g.:
# --- OpenAI-compatible ---
# export OPENAI_BASE_URL="https://api.openai.com/v1"
# export OPENAI_API_KEY="sk-xxxx"
# export OPENAI_MODEL="gpt-4o-mini"
# export OPENAI_SMALL_FAST_MODEL="gpt-4o-mini"

# --- Anthropic-compatible ---
# export ANTHROPIC_BASE_URL="https://api.example.com/anthropic"
# export ANTHROPIC_API_KEY="sk-xxxx"
# export ANTHROPIC_MODEL="claude-3-5-sonnet"
# export ANTHROPIC_SMALL_FAST_MODEL="claude-3-haiku"

# --- Gemini ---
# export GEMINI_API_KEY="AIzaSy..."

# --- Qwen / DashScope ---
# export OPENAI_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"
# export OPENAI_API_KEY="sk-xxxx"
# export OPENAI_MODEL="qwen-max"
# export OPENAI_SMALL_FAST_MODEL="qwen-turbo"
EOF
}

_ai_write_profile_from_current_block() {
  awk -v s="$AI_RC_START" -v e="$AI_RC_END" '
    $0~s{inblk=1;next} $0~e{inblk=0;next}
    inblk{print}
  ' "$AI_RC_FILE" >"$1"
}

_ai_version() { echo "ai-switch 0.1.1"; }

# ------ main ------
ai() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    list|"") echo "Available profiles:"; _ai_list_profiles ;;
    current) echo "Current profile: $(_ai_current)" ;;
    version|--version|-v) _ai_version ;;
    switch)
      local name="${1:-}"
      if [ -z "$name" ] && command -v fzf >/dev/null 2>&1; then
        name="$(_ai_list_profiles | fzf --prompt='Select AI profile> ' --height=40% --reverse)"
      fi
      if [ -z "$name" ]; then echo "Usage: ai switch <profile>"; return 1; fi
      if ! _ai_validate_name "$name"; then echo "Invalid profile name: $name"; return 1; fi
      local file; file="$(_ai_profile_path "$name")"
      if [ ! -f "$file" ]; then echo "Not found: $file"; return 1; fi
      _ai_source_profile_now "$file"
      _ai_write_block_to_rc "$file"
      printf '%s\n' "$name" >"$AI_PROFILE_STATE"
      export AI_PROFILE="$name"
      echo "✅ Switched to: $name (current shell active; new shells inherit)"
      ;;
    add)
      local name="${1:-}"; shift || true
      local force=0 switch_after=0 from_current=0
      local args=()
      local a
      while [ -n "${1:-}" ]; do
        a="$1"; shift
        case "$a" in
          --force) force=1 ;;
          --switch) switch_after=1 ;;
          --from-current) from_current=1 ;;
          *) args+=("$a") ;;
        esac
      done
      if [ -z "$name" ]; then
        cat <<'EOF'
Usage:
  ai add <name>                 # create from template and open $EDITOR
  ai add <name> KEY=VAL ...     # create from key-value pairs
  ai add <name> --from-current  # snapshot rc AI block into a profile
Options:
  --force overwrite if exists   --switch switch after creation
EOF
        return 1
      fi
      if ! _ai_validate_name "$name"; then echo "Invalid profile name: $name"; return 1; fi
      local file; file="$(_ai_profile_path "$name")"
      if [ -f "$file" ] && [ "$force" -ne 1 ]; then echo "Already exists: $file (use --force)"; return 1; fi
      if [ "$from_current" -eq 1 ]; then
        if ! awk -v s="$AI_RC_START" -v e="$AI_RC_END" 'BEGIN{f=0} $0~s{f=1} $0~e{f=0} END{exit f?0:1}' "$AI_RC_FILE" 2>/dev/null; then
          echo "No AI block found in $AI_RC_FILE"; return 1
        fi
        _ai_write_profile_from_current_block "$file"
        echo "✅ Created from current rc block: $file"
      elif [ "${#args[@]}" -gt 0 ]; then
        _ai_write_profile_from_kv "$file" "${args[@]}"
        echo "✅ Created: $file"
      else
        _ai_template >"$file"; echo "✅ Template created: $file"; ${EDITOR:-vi} "$file"
      fi
      [ "$switch_after" -eq 1 ] && ai switch "$name" || echo "Run: ai switch $name"
      ;;
    remove)
      local name="${1:-}"
      if [ -z "$name" ]; then echo "Usage: ai remove <profile>"; return 1; fi
      if ! _ai_validate_name "$name"; then echo "Invalid profile name: $name"; return 1; fi
      local file; file="$(_ai_profile_path "$name")"
      if [ ! -f "$file" ]; then echo "Not found: $file"; return 1; fi
      if [ "$(_ai_current)" = "$name" ]; then
        local vars v
        vars="$(_ai_extract_vars_from_block)"
        if ! _ai_remove_block_from_rc; then
          echo "Error: Failed to update rc file" >&2
          return 1
        fi
        rm -f "$file"
        for v in $vars; do unset "$v"; done
        rm -f "$AI_PROFILE_STATE"
        unset AI_PROFILE
        echo "✅ Removed current profile: $name"
      else
        rm -f "$file"
        echo "✅ Removed: $name"
      fi
      ;;
    edit)
      local name="${1:-}"; [ -z "$name" ] && { echo "Usage: ai edit <profile>"; return 1; }
      ${EDITOR:-vi} "$(_ai_profile_path "$name")"
      ;;
    doctor)
      echo "AI_PROFILES_DIR=$AI_PROFILES_DIR"
      echo "AI_RC_FILE=$AI_RC_FILE"
      echo "Current: $(_ai_current)"
      printf 'Vars in rc block: '; _ai_extract_vars_from_block | tr '\n' ' '; echo
      ;;
    *)
      cat <<'EOF'
Usage:
  ai list                   List profiles
  ai current                Show current profile
  ai switch <profile>       Switch (fzf-enabled if installed)
  ai add <name> [opts]      Add new profile (template/kv/from-current)
  ai remove <profile>       Remove profile file (clears if current)
  ai edit <profile>         Edit profile file
  ai doctor                 Diagnostics
  ai version                Show version
EOF
      ;;
  esac
}
# === /AI profile switcher ===
