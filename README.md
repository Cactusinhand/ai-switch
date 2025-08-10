# ai-switch

Instantly switch AI provider environment profiles in your shell.

## Why?
- Stop commenting/uncommenting blocks in `~/.bashrc`.
- Keep clean, portable `export`-only profiles.
- Make new terminals inherit your current choice automatically.

## Install
```bash
# Option 1: Simple install
./scripts/install.sh

# Option 2: Manual install
cp ai-switch.sh ~/.ai-switch.sh
echo '[ -f "$HOME/.ai-switch.sh" ] && source "$HOME/.ai-switch.sh"' >> ~/.bashrc  # or ~/.zshrc

Then reload your shell:
source ~/.bashrc  # or: source ~/.zshrc

## Usage

ai list
ai current
ai switch <profile>          # fzf-enabled if installed
ai add <name>                # open template in $EDITOR
ai add <name> KEY=VAL ...    # quick create
ai add <name> --from-current # snapshot rc AI block
ai edit <name>
ai doctor
ai version


## Contributing

Thanks for helping!

## Development
```bash
# Run tests
./scripts/test.sh

# Run lint checks
./scripts/lint.sh

# Quick syntax check
bash -n ai-switch.sh
```
