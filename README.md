# ai-switch

Instantly switch AI provider environment profiles in your shell.

## Usage
```
ai list
ai current | ai status
ai switch <profile> | ai checkout <profile>          # fzf-enabled if installed
ai add <name>                # open template in $EDITOR
ai add <name> KEY=VAL ...    # quick create
ai add <name> --from-current # snapshot rc AI block
ai remove <profile>          # delete profile; clears current if active
ai edit <name>
ai doctor
ai version
```

Profiles are stored in `$AI_PROFILES_DIR` (defaults to `~/.ai-profiles`).

## Why?
- Stop commenting/uncommenting blocks in `~/.bashrc`.
- Keep clean, portable `export`-only profiles.
- Make new terminals inherit your current choice automatically.

## Install
```bash
# Option 1: One‑liner (curl | bash)
curl -fsSL https://raw.githubusercontent.com/Cactusinhand/ai-switch/main/install.sh | bash

# Option 2: Simple local install
./scripts/install.sh

# Option 3: Manual install
cp ai-switch.sh ~/.ai-switch.sh
echo '[ -f "$HOME/.ai-switch.sh" ] && source "$HOME/.ai-switch.sh"' >> ~/.bashrc  # or ~/.zshrc

# Then reload your shell:
source ~/.bashrc  # or: source ~/.zshrc
```

Advanced:
- Uninstall: `curl -fsSL https://raw.githubusercontent.com/Cactusinhand/ai-switch/main/install.sh | bash -s -- --uninstall`
- Custom install prefix: set `PREFIX`, e.g. `PREFIX=/usr/local curl -fsSL .../install.sh | bash`
- Custom rc file: set `AI_RC_FILE`, e.g. `AI_RC_FILE=$HOME/.bash_profile curl -fsSL .../install.sh | bash`
- Seed example profiles: installer copies `examples/profiles/*` into `$AI_PROFILES_DIR` (default `~/.ai-profiles`) only if the directory is empty (first install). Set `AI_INSTALL_TEMPLATES=0` to disable. Override dir with `AI_PROFILES_DIR=/path/to/dir`.

中文快速安装:
- 一键安装: `curl -fsSL https://raw.githubusercontent.com/Cactusinhand/ai-switch/main/install.sh | bash`
- 卸载: `curl -fsSL https://raw.githubusercontent.com/Cactusinhand/ai-switch/main/install.sh | bash -s -- --uninstall`
 - 模板: 首次安装且目录为空时，将 `examples/profiles/*` 复制到 `~/.ai-profiles`。可通过 `AI_INSTALL_TEMPLATES=0` 关闭，或用 `AI_PROFILES_DIR=/path` 指定目录。

## Development
```bash
# Run tests
./scripts/test.sh

# Run lint checks
./scripts/lint.sh

# Quick syntax check
bash -n ai-switch.sh
```
