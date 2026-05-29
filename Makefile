# Makefile - quality and convenience targets for the RHEL kernel / Oracle DB
# automation repository.
#
# Targets:
#   make help        Show this help.
#   make lint        Alias for shellcheck.
#   make shellcheck  Run ShellCheck over all shell scripts.
#   make test        Run the Bats test suite (if bats is installed).
#   make syntax      bash -n syntax check over all scripts (no external deps).
#   make docs        List / sanity-check the documentation set.
#   make tree        Print the repository tree (excluding .git and artefacts).
#   make perms       Mark all *.sh scripts executable.

SHELL := /bin/bash
SCRIPTS := $(shell find . -path ./.git -prune -o -type f -name '*.sh' -print)

.PHONY: help lint shellcheck test syntax docs tree perms

help:
	@grep -E '^#   make ' Makefile | sed 's/^#   /  /'

lint: shellcheck

shellcheck:
	@bash scripts/tests/shellcheck_all.sh

syntax:
	@echo "Running 'bash -n' over $(words $(SCRIPTS)) script(s)..."
	@rc=0; for f in $(SCRIPTS); do \
		bash -n "$$f" || { echo "SYNTAX ERROR: $$f"; rc=1; }; \
	done; \
	if [ $$rc -eq 0 ]; then echo "Syntax OK."; else exit 1; fi

test:
	@if command -v bats >/dev/null 2>&1; then \
		bats scripts/tests/bats/; \
	else \
		echo "WARN: bats not installed; skipping tests."; \
	fi

docs:
	@echo "Documentation files:"; \
	for d in docs/*.md README.md LICENSE; do \
		if [ -f "$$d" ]; then echo "  OK   $$d"; else echo "  MISS $$d"; fi; \
	done

tree:
	@if command -v tree >/dev/null 2>&1; then \
		tree -a -I '.git|output|build|sources|*.tar.gz|*.rpm'; \
	else \
		find . -path ./.git -prune -o -print | sort; \
	fi

perms:
	@echo "Marking shell scripts executable..."
	@find . -path ./.git -prune -o -type f -name '*.sh' -exec chmod +x {} +
	@echo "Done."
