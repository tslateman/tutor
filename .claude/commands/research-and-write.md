---
description: Research a topic and write guides for the tutor repo
allowed-tools: [Task, Read, Glob, Grep, Edit, Write, WebSearch, WebFetch, Bash]
---

Research a topic, then write or update guides in this repository.

## Input

The user's message contains the topic and optionally specific sources to
investigate.

## Step 1: Check Existing Coverage

Read the CLAUDE.md table of contents. Search for existing mentions of the topic
across `how/`, `why/`, and `learn/` directories. Note what already exists and
where gaps are.

## Step 2: Research

Spawn 2-4 parallel research agents (sonnet, general-purpose) to investigate the
topic. Each agent should:

- Cover a distinct angle or source group
- Produce structured output with: key concepts, patterns, tradeoffs, sources
- Do research only, no file edits

## Step 3: Plan Guides

Based on research results and existing coverage, decide what to write:

| Directory | Contains                    | Write here when...                     |
| --------- | --------------------------- | -------------------------------------- |
| `how/`    | Commands, syntax, reference | The topic has concrete mechanics       |
| `why/`    | Mental models, frameworks   | The topic has principles and tradeoffs |
| `learn/`  | 8-lesson progressive plans  | The topic warrants structured study    |

Present the plan to the user before writing. State which files to create or
update.

## Step 4: Write

After user confirms the plan:

- Match the style of existing guides in the target directory
- Use tables for comparisons and quick reference
- Add cross-references (`## See Also`) linking to related guides
- Add language specifiers on all fenced code blocks
- Update the CLAUDE.md table entry for any new files

## Step 5: Format and Verify

Run `prettier --write` on all written markdown files. Run `make lint` to check
for issues. Fix any errors (ignore pre-existing passive voice warnings in other
files).
