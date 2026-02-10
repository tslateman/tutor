# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Purpose

This is a personal reference repository containing cheat sheets and learning
materials.

## Contents

### how/

Commands, syntax, quick reference.

| File                     | Topics                                                      |
| ------------------------ | ----------------------------------------------------------- |
| `agent-orchestration.md` | Multi-agent patterns, delegation, worktrees, monitoring     |
| `ai-cli.md`              | Claude Code, context files, prompting, verification         |
| `docker.md`              | Images, containers, Dockerfile, Compose, networking         |
| `git.md`                 | Commits, branches, merging, rebasing, remotes, workflows    |
| `http.md`                | curl, headers, status codes, REST conventions               |
| `jq.md`                  | JSON processing, filters, transforms, practical examples    |
| `k8s.md`                 | Pods, deployments, services, debugging, OrbStack            |
| `learning-a-language.md` | Phases, daily routine, techniques, tools, anti-patterns     |
| `macos.md`               | Homebrew, defaults, Spotlight, launchctl, AppleScript       |
| `neovim.md`              | LazyVim keybindings, Telescope, navigation, code actions    |
| `postgres.md`            | psql commands, indexes, window functions, admin queries     |
| `python.md`              | Data structures, comprehensions, typing, async              |
| `regex.md`               | Patterns, quantifiers, groups, lookahead, language-specific |
| `rust.md`                | Ownership, borrowing, lifetimes, traits, cargo              |
| `security-scanning.md`   | Scorecard, Trivy, GuardDog, secrets, supply chain           |
| `shell.md`               | Scripting patterns, loops, conditionals, functions          |
| `sql.md`                 | General SQL, joins, CTEs, window functions                  |
| `testing.md`             | pytest, Jest, Go, Rust test commands, patterns              |
| `tmux.md`                | Sessions, windows, panes, copy mode, configuration          |
| `typescript.md`          | Types, generics, utility types, patterns                    |
| `unix.md`                | Shell commands, file ops, text processing, SSH              |

### why/

Mental models, principles, frameworks.

| File                 | Topics                                                 |
| -------------------- | ------------------------------------------------------ |
| `complexity.md`      | Essential vs accidental, techniques, heuristics        |
| `debugging.md`       | Scientific method, bisection, isolation techniques     |
| `learning.md`        | Retention techniques, spaced repetition, active recall |
| `problem-solving.md` | Polya's method, divide-and-conquer, rubber duck        |
| `testing.md`         | Pyramid, strategy, doubles, TDD, anti-patterns         |
| `thinking.md`        | Mental models, systems thinking, asking good questions |

### learn/

Progressive lesson plans with exercises.

| File                               | Topics                                             |
| ---------------------------------- | -------------------------------------------------- |
| `ghostty-lesson-plan.md`           | 8 lessons from install to workflow integration     |
| `git-lesson-plan.md`               | 8 lessons from commits to workflows, with projects |
| `github-lesson-plan.md`            | 8 lessons from repos to Actions and API            |
| `golang-lesson-plan.md`            | 8 lessons from basics to concurrency               |
| `python-lesson-plan.md`            | 8 lessons from basics to async                     |
| `rust-lesson-plan.md`              | 8 lessons from ownership to lifetimes              |
| `technical-writing-lesson-plan.md` | 8 lessons on clarity, structure, audience          |
| `tmux-lesson-plan.md`              | 8 lessons from basics to scripting, with projects  |
| `typescript-lesson-plan.md`        | 8 lessons from types to advanced patterns          |

## Commands

```bash
make lint      # Run markdownlint and vale
make format    # Format with prettier
make fix       # Format then lint
make sync      # Download vale style packages
make setup     # Install git hooks
make new       # Create new guide (NAME=foo TYPE=how|why)
```
