.PHONY: help lint format check fix setup sync prose links new dev build preview check-refs check-counts audit-sidebar check-structure

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
	@echo "  new           Create new guide (NAME=foo TYPE=how|why|learn)"
	@echo "  audit-sidebar Verify all docs appear in sidebar"
	@echo "  check-structure  Verify lesson plan structure"

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
	claude -p "/elements-of-style:writing-clearly-and-concisely src/content/docs/how/ src/content/docs/why/ src/content/docs/learn/"

# Create a new guide
new:
ifndef NAME
	$(error NAME is required. Usage: make new NAME=kubernetes TYPE=how)
endif
ifndef TYPE
	$(error TYPE is required. Usage: make new NAME=kubernetes TYPE=how)
endif
	@./scripts/new-guide.sh "$(NAME)" "$(TYPE)"

# Verify See Also links resolve to actual files
check-refs:
	@err=0; \
	for f in src/content/docs/**/*.md; do \
		dir=$$(dirname "$$f"); \
		sed -n '/^## See Also/,/^## /p' "$$f" \
		| grep -oE '\([^)]+\.md\)' \
		| tr -d '()' \
		| grep -v '^http' \
		| while read -r link; do \
			target="$$dir/$$link"; \
			if [ ! -f "$$target" ]; then \
				echo "BROKEN: $$f -> $$link"; \
				exit 1; \
			fi; \
		done || err=1; \
	done; \
	if [ "$$err" = "1" ]; then exit 1; fi

# Verify CLAUDE.md table row counts match actual file counts
check-counts:
	@err=0; \
	for dir in how why learn; do \
		actual=$$(find src/content/docs/$$dir -maxdepth 1 -name '*.md' | wc -l | tr -d ' '); \
		listed=$$(sed -n "/^### $$dir\//,/^##[# ]/p" CLAUDE.md | grep -c '| `.*\.md`'); \
		if [ "$$actual" != "$$listed" ]; then \
			echo "MISMATCH: $$dir/ has $$actual files but CLAUDE.md lists $$listed"; \
			err=1; \
		fi; \
	done; \
	if [ "$$err" = "1" ]; then exit 1; fi; \
	for mapping in "how:Reference" "why:Mental Models" "learn:Lesson Plans"; do \
		dir=$${mapping%%:*}; \
		label=$${mapping#*:}; \
		actual=$$(find src/content/docs/$$dir -maxdepth 1 -name '*.md' | wc -l | tr -d ' '); \
		listed=$$(grep "| $$label " README.md | awk -F'|' '{print $$4}' | tr -d ' '); \
		if [ "$$actual" != "$$listed" ]; then \
			echo "MISMATCH: $$dir/ has $$actual files but README.md lists $$listed"; \
			err=1; \
		fi; \
	done; \
	if [ "$$err" = "1" ]; then exit 1; fi

# Verify all .md files appear in astro.config.mjs sidebar
audit-sidebar:
	@err=0; \
	for file in $$(find src/content/docs/how src/content/docs/why src/content/docs/learn -maxdepth 1 -name '*.md' | sort); do \
		slug=$$(echo "$$file" | sed 's/^src\/content\/docs\///;s/\.md$$//'); \
		if ! grep -q "slug: \"$$slug\"" astro.config.mjs; then \
			echo "MISSING: $$file (slug: $$slug) not found in sidebar"; \
			err=1; \
		fi; \
	done; \
	if [ "$$err" = "1" ]; then exit 1; fi; \
	echo "All docs verified in sidebar"

# Verify lesson plan structure (8 lessons, required sections)
check-structure:
	@./scripts/check-lesson-structure.sh
