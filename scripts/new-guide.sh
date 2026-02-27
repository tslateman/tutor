#!/bin/bash
set -e

NAME="$1"
TYPE="$2"

if [ -z "$NAME" ] || [ -z "$TYPE" ]; then
  echo "Usage: $0 NAME TYPE"
  echo "  TYPE must be 'how', 'why', or 'learn'"
  exit 1
fi

if [ "$TYPE" != "how" ] && [ "$TYPE" != "why" ] && [ "$TYPE" != "learn" ]; then
  echo "Error: TYPE must be 'how', 'why', or 'learn'"
  exit 1
fi

# Title-case the name: convert hyphens to spaces, capitalize each word
# "api-design" → "Api Design", "system-design" → "System Design"
TITLE=$(echo "$NAME" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

# Build slug: learn/ files get "-lesson-plan" suffix
if [ "$TYPE" = "learn" ]; then
  SLUG="$TYPE/${NAME}-lesson-plan"
  FILE="src/content/docs/$TYPE/${NAME}-lesson-plan.md"
else
  SLUG="$TYPE/$NAME"
  FILE="src/content/docs/$TYPE/$NAME.md"
fi

if [ -f "$FILE" ]; then
  echo "Error: $FILE already exists"
  exit 1
fi

if [ "$TYPE" = "how" ]; then
  cat > "$FILE" <<EOF
---
title: "$TITLE"
description: "Commands, syntax, and quick reference for $NAME."
---

## Quick Reference

| Command / Pattern | Description |
| ----------------- | ----------- |
| \`example\`         | What it does |

## Basic Usage

\`\`\`bash
# Example command
$NAME --help
\`\`\`

## See Also

- Related concepts and reference materials
EOF
elif [ "$TYPE" = "why" ]; then
  cat > "$FILE" <<EOF
---
title: "$TITLE"
description: "Mental models and principles for $NAME."
---

## Core Concepts

### First Principle

Explanation of the fundamental idea.

**Example:**

\`\`\`text
Concrete illustration of the concept
\`\`\`

## See Also

- Related concepts and reference materials
EOF
else
  cat > "$FILE" <<EOF
---
title: "$TITLE Lesson Plan"
description: "Eight lessons covering the fundamentals of $NAME, with progressive exercises and checkpoints."
---

A progressive curriculum to master $NAME through hands-on practice.

## Lesson 1: Foundations

**Goal:** Understand the core concepts of $NAME.

### Concepts

Introduce the fundamental ideas and why they matter.

### Exercises

1. **First exercise**

   \`\`\`bash
   # Example command
   \`\`\`

2. **Second exercise**

   \`\`\`bash
   # Example command
   \`\`\`

### Checkpoint

Verify understanding before moving forward.

---

## Lesson 2: Building on Basics

**Goal:** Apply foundational concepts in practical scenarios.

### Concepts

Expand on the foundations with more complex patterns.

### Exercises

1. **First exercise**

   \`\`\`bash
   # Example command
   \`\`\`

2. **Second exercise**

   \`\`\`bash
   # Example command
   \`\`\`

### Checkpoint

Confirm progress before advancing.

---

<!-- Lessons 3-8: Follow the same structure as Lessons 1-2 above -->
<!-- - Lesson 3: [topic] -->
<!-- - Lesson 4: [topic] -->
<!-- - Lesson 5: [topic] -->
<!-- - Lesson 6: [topic] -->
<!-- - Lesson 7: [topic] -->
<!-- - Lesson 8: [topic] -->

## See Also

- Related concepts and reference materials
EOF
fi

SIDEBAR_LABEL="$TITLE"
SIDEBAR_LINE="{ label: \"$SIDEBAR_LABEL\", slug: \"$SLUG\" }"

echo "Created $FILE"
echo ""
echo "Next steps:"
echo "  1. Add this line to astro.config.mjs sidebar (in the '$TYPE' section):"
echo ""
echo "     $SIDEBAR_LINE"
echo ""
echo "  2. Add content to the file"
