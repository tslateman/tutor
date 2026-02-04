.PHONY: lint format check fix

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
