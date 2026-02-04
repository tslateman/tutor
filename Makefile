.PHONY: help lint format check fix setup sync

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  lint    Run markdownlint and vale"
	@echo "  format  Format markdown with prettier"
	@echo "  check   Check formatting (no changes)"
	@echo "  fix     Format then lint"
	@echo "  setup   Install git hooks"
	@echo "  sync    Download vale style packages"

# Lint markdown files
lint:
	markdownlint '**/*.md' --ignore .vale
	vale cheatsheets/*.md CLAUDE.md

# Format markdown files
format:
	prettier --write '**/*.md'

# Check formatting (no changes)
check:
	prettier --check '**/*.md'

# Fix everything
fix: format lint

# Install git hooks
setup:
	cp hooks/pre-commit .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
	@echo "Git hooks installed"

# Download vale style packages
sync:
	vale sync
