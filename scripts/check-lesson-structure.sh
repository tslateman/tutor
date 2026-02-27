#!/bin/bash
set -euo pipefail

err=0
dir="src/content/docs/learn"

for file in "$dir"/*-lesson-plan.md; do
  name=$(basename "$file")
  failed=""

  # Count ## Lesson N: headings — must be exactly 8
  lesson_count=$(grep -c '^## Lesson [0-9]' "$file")
  if [ "$lesson_count" -ne 8 ]; then
    failed="expected 8 lessons, found $lesson_count"
  fi

  # Check per-lesson requirements by extracting each lesson's content
  for n in 1 2 3 4 5 6 7 8; do
    # Extract content between "## Lesson N:" and the next "## " heading
    lesson_content=$(awk "/^## Lesson $n:/{found=1; next} found && /^## [^#]/{exit} found" "$file")

    if [ -z "$lesson_content" ]; then
      failed="${failed:+$failed; }Lesson $n not found"
      continue
    fi

    if ! echo "$lesson_content" | grep -q '^\*\*Goal:\*\*'; then
      failed="${failed:+$failed; }Lesson $n missing **Goal:**"
    fi

    if ! echo "$lesson_content" | grep -q '^### Exercises' && \
       ! echo "$lesson_content" | grep -q '^### Concepts'; then
      failed="${failed:+$failed; }Lesson $n missing ### Exercises or ### Concepts"
    fi

    if ! echo "$lesson_content" | grep -q '^### Checkpoint'; then
      failed="${failed:+$failed; }Lesson $n missing ### Checkpoint"
    fi
  done

  # File must contain ## See Also
  if ! grep -q '^## See Also' "$file"; then
    failed="${failed:+$failed; }missing ## See Also section"
  fi

  if [ -n "$failed" ]; then
    echo "FAIL: $name — $failed"
    err=1
  else
    echo "OK: $name"
  fi
done

if [ "$err" -eq 1 ]; then
  exit 1
fi
