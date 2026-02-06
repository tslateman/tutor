#!/bin/bash
set -e

NAME="$1"
TYPE="$2"

if [ -z "$NAME" ] || [ -z "$TYPE" ]; then
  echo "Usage: $0 NAME TYPE"
  echo "  TYPE must be 'how' or 'why'"
  exit 1
fi

if [ "$TYPE" != "how" ] && [ "$TYPE" != "why" ]; then
  echo "Error: TYPE must be 'how' or 'why'"
  exit 1
fi

FILE="$TYPE/$NAME.md"

if [ -f "$FILE" ]; then
  echo "Error: $FILE already exists"
  exit 1
fi

if [ "$TYPE" = "how" ]; then
  cat > "$FILE" <<EOF
# ${NAME^}

Brief description of what $NAME is and when to use it.

## Quick Reference

| Command / Pattern | Description |
| ----------------- | ----------- |
| \`example\`         | What it does |

## Basic Usage

\`\`\`bash
# Example command
$NAME --help
\`\`\`
EOF
else
  cat > "$FILE" <<EOF
# ${NAME^}

Why this matters and when to apply these principles.

## Core Concepts

### First Principle

Explanation of the fundamental idea.

**Example:**

\`\`\`text
Concrete illustration of the concept
\`\`\`
EOF
fi

echo "Created $FILE"
echo ""
echo "Next steps:"
echo "  1. Update CLAUDE.md table in $TYPE/ section"
echo "  2. Update README.md table"
