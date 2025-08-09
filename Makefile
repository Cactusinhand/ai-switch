PREFIX ?= $(HOME)
RC ?= $(shell [ -n "$$ZSH_VERSION" ] || [ "$$SHELL" = "/bin/zsh" ] && echo $(HOME)/.zshrc || echo $(HOME)/.bashrc)

install:
	install -m 0644 ai-switch.sh $(PREFIX)/.ai-switch.sh
	@grep -q 'source "$(HOME)/.ai-switch.sh"' $(RC) 2>/dev/null || \
		echo '\n# ai-switch\n[ -f "$(HOME)/.ai-switch.sh" ] && source "$(HOME)/.ai-switch.sh"' >> $(RC)
	@echo 'Installed to $(PREFIX)/.ai-switch.sh. Source: $(RC)'

uninstall:
	rm -f $(PREFIX)/.ai-switch.sh
	@sed -i.bak "/source \"\$HOME\/\.ai-switch\.sh\"/d" $(RC) || true
	@echo 'Uninstalled. Please remove AI block from rc manually if needed.'

lint:
	shellcheck ai-switch.sh || true
	test -d completion && shellcheck completion/* || true
	test -d tests && echo OK

 test:
	bats tests