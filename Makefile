.PHONY: lint format check fix setup

# Lint markdown files
lint:
	markdownlint '**/*.md'

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
