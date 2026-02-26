.PHONY: help lint format check fix setup sync prose links new dev build preview

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  dev     Start Astro dev server"
	@echo "  build   Build Astro site"
	@echo "  preview Preview Astro production build"
	@echo "  lint    Run markdownlint, vale, and link checker"
	@echo "  format  Format markdown with prettier"
	@echo "  check   Check formatting (no changes)"
	@echo "  fix     Format then lint"
	@echo "  setup   Install git hooks"
	@echo "  sync    Download vale style packages"
	@echo "  prose   Review prose with Claude (Strunk's rules)"
	@echo "  links   Check markdown links (internal only)"
	@echo "  new     Create new guide (NAME=foo TYPE=how|why|learn)"

# Astro dev server
dev:
	npm run dev

# Build Astro site
build:
	npm run build

# Preview Astro production build
preview:
	npm run preview

# Markdown sources (excludes node_modules, .vale)
MD_FILES = src/content/docs/**/*.md CLAUDE.md README.md

# Lint markdown files
lint:
	markdownlint $(MD_FILES)
	vale src/content/docs/how/*.md src/content/docs/why/*.md src/content/docs/learn/*.md CLAUDE.md
	lychee --offline $(MD_FILES)

# Check markdown links (internal only, fast)
links:
	lychee --offline $(MD_FILES)

# Format markdown files
format:
	prettier --write $(MD_FILES)

# Check formatting (no changes)
check:
	prettier --check $(MD_FILES)

# Fix everything
fix: format lint

# Install git hooks
setup:
	pre-commit install
	@echo "Git hooks installed"

# Download vale style packages
sync:
	vale sync

# Review prose with Claude (Strunk's Elements of Style)
prose:
	claude -p "/elements-of-style:writing-clearly-and-concisely src/content/docs/how/ src/content/docs/why/"

# Create a new guide
new:
ifndef NAME
	$(error NAME is required. Usage: make new NAME=kubernetes TYPE=how)
endif
ifndef TYPE
	$(error TYPE is required. Usage: make new NAME=kubernetes TYPE=how)
endif
	@./scripts/new-guide.sh "$(NAME)" "$(TYPE)"
