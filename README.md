# ai-switch

Instantly switch AI provider environment profiles in your shell.

## Why?
- Stop commenting/uncommenting blocks in `~/.bashrc`.
- Keep clean, portable `export`-only profiles.
- Make new terminals inherit your current choice automatically.

## Install
```bash
curl -fsSL https://raw.githubusercontent.com/<you>/ai-switch/main/install.sh | bash
# Or: make install

Then reload your shell:

source ~/.bashrc  # or: source ~/.zshrc

Usage

ai list
ai current
ai switch <profile>          # fzf-enabled if installed
ai add <name>                # open template in $EDITOR
ai add <name> KEY=VAL ...    # quick create
ai add <name> --from-current # snapshot rc AI block
ai edit <name>
ai doctor
ai version


# Contributing to ai-switch

Thanks for helping!

## Dev loop
```bash
# run lint & tests locally (requires Bats)
make lint
make test
```
