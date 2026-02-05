# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Purpose

This is a personal reference repository containing cheat sheets and learning
materials.

## Contents

### how/

Commands, syntax, quick reference.

| File            | Topics                                                      |
| --------------- | ----------------------------------------------------------- |
| `docker.md`     | Images, containers, Dockerfile, Compose, networking         |
| `git.md`        | Commits, branches, merging, rebasing, remotes, workflows    |
| `jq.md`         | JSON processing, filters, transforms, practical examples    |
| `macos.md`      | Homebrew, defaults, Spotlight, launchctl, AppleScript       |
| `neovim.md`     | LazyVim keybindings, Telescope, navigation, code actions    |
| `postgres.md`   | psql commands, indexes, window functions, admin queries     |
| `python.md`     | Data structures, comprehensions, typing, async              |
| `regex.md`      | Patterns, quantifiers, groups, lookahead, language-specific |
| `sql.md`        | General SQL, joins, CTEs, window functions                  |
| `tmux.md`       | Sessions, windows, panes, copy mode, configuration          |
| `typescript.md` | Types, generics, utility types, patterns                    |
| `unix.md`       | Shell commands, file ops, text processing, SSH              |

### why/

Mental models, principles, frameworks.

| File            | Topics                                                 |
| --------------- | ------------------------------------------------------ |
| `complexity.md` | Essential vs accidental, techniques, heuristics        |
| `learning.md`   | Retention techniques, spaced repetition, active recall |
| `thinking.md`   | Mental models, systems thinking, asking good questions |

## Commands

```bash
make lint      # Run markdownlint and vale
make format    # Format with prettier
make fix       # Format then lint
make sync      # Download vale style packages
make setup     # Install git hooks
```
