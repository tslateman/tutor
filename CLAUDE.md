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
| `ci-cd.md`               | GitHub Actions, caching, matrix builds, deployment          |
| `claude-code.md`         | Agents, hooks, plugins, MCP, memory, settings, teams        |
| `cli-pipelines.md`       | Pipes, substitution, xargs, fzf, history expansion          |
| `cryptography.md`        | Hashing, encryption, certificates, TLS, openssl             |
| `debugging.md`           | pdb, lldb, strace/dtruss, py-spy, hyperfine, flame graphs   |
| `diagramming.md`         | Diagram types, Mermaid syntax, ASCII patterns, concept maps |
| `docker.md`              | Images, containers, Dockerfile, Compose, networking         |
| `filesystem-advanced.md` | Atomic operations, locking, inotify/FSEvents, performance   |
| `filesystem.md`          | FHS, inodes, permissions, file descriptors, security        |
| `git.md`                 | Commits, branches, merging, rebasing, remotes, workflows    |
| `http.md`                | curl, headers, status codes, REST conventions               |
| `jq.md`                  | JSON processing, filters, transforms, practical examples    |
| `k8s.md`                 | Pods, deployments, services, debugging, OrbStack            |
| `learning-a-language.md` | Phases, daily routine, techniques, tools, anti-patterns     |
| `macos.md`               | Homebrew, defaults, Spotlight, launchctl, AppleScript       |
| `neovim.md`              | LazyVim keybindings, Telescope, LSP, DAP, config patterns   |
| `performance.md`         | Profiling, benchmarking, flame graphs, load testing         |
| `postgres.md`            | psql commands, indexes, window functions, admin queries     |
| `python.md`              | Data structures, comprehensions, typing, async              |
| `python-cli.md`          | Typer, Click, argparse, Django wrappers, packaging          |
| `regex.md`               | Patterns, quantifiers, groups, lookahead, language-specific |
| `rust.md`                | Ownership, borrowing, lifetimes, traits, cargo              |
| `security-scanning.md`   | Scorecard, Trivy, GuardDog, secrets, supply chain           |
| `shell.md`               | Scripting patterns, loops, conditionals, functions          |
| `sql.md`                 | General SQL, joins, CTEs, window functions                  |
| `system-design.md`       | Load balancing, caching, consistency, capacity estimation   |
| `terminal-emulators.md`  | iTerm2 vs Ghostty, rendering, tmux -CC, decision guide      |
| `testing.md`             | pytest, Jest, Go, Rust test commands, patterns              |
| `tmux.md`                | Sessions, windows, panes, copy mode, configuration          |
| `typescript.md`          | Types, generics, utility types, patterns                    |
| `unix.md`                | Shell commands, file ops, text processing, SSH              |

### why/

Mental models, principles, frameworks.

| File                          | Topics                                                   |
| ----------------------------- | -------------------------------------------------------- |
| `agent-memory.md`             | Temporal tracking, cognitive layers, decay, retrieval    |
| `ai-adoption.md`              | Tooling without mandate, what stays human, codeowners    |
| `api-design.md`               | REST vs GraphQL vs gRPC, pagination, versioning, errors  |
| `cli-first.md`                | Why terminal-first, core stack, tool replacements, habit |
| `complexity.md`               | Essential vs accidental, techniques, heuristics          |
| `debugging.md`                | Scientific method, bisection, isolation techniques       |
| `information-architecture.md` | Four systems, Diataxis, findability heuristics           |
| `knowledge-design.md`         | Taxonomy, CTA, mental modeling, semantic labeling        |
| `learning.md`                 | Retention techniques, spaced repetition, active recall   |
| `orchestration.md`            | K8s-to-agents parallels, context routing, failure modes  |
| `problem-solving.md`          | Polya's method, divide-and-conquer, rubber duck          |
| `reasoning.md`                | Fallacies, cognitive biases, debiasing, System 1/2       |
| `specification.md`            | Specification spectrum, DbC, TLA+, agent constraints     |
| `testing.md`                  | Pyramid, strategy, doubles, TDD, anti-patterns           |
| `thinking.md`                 | Mental models, systems thinking, asking good questions   |

### learn/

Progressive lesson plans with exercises.

| File                                      | Topics                                                      |
| ----------------------------------------- | ----------------------------------------------------------- |
| `agentic-workflows-lesson-plan.md`        | 8 lessons on orchestrating AI agent systems                 |
| `concurrency-lesson-plan.md`              | 8 lessons on threads, channels, async across Go/Python/Rust |
| `context-complexity-lesson-plan.md`       | 8 lessons on managing context as a finite resource          |
| `cryptography-lesson-plan.md`             | 8 lessons from hashing to TLS and key management            |
| `data-models-lesson-plan.md`              | 8 lessons from ER diagrams to model selection               |
| `ghostty-lesson-plan.md`                  | 8 lessons from install to workflow integration              |
| `git-lesson-plan.md`                      | 8 lessons from commits to workflows, with projects          |
| `github-lesson-plan.md`                   | 8 lessons from repos to Actions and API                     |
| `golang-lesson-plan.md`                   | 8 lessons from basics to concurrency                        |
| `information-architecture-lesson-plan.md` | 8 lessons from organization to full audit                   |
| `networking-lesson-plan.md`               | 8 lessons from DNS to sockets and debugging                 |
| `operating-systems-lesson-plan.md`        | 8 lessons from processes to system call tracing             |
| `python-lesson-plan.md`                   | 8 lessons from basics to async                              |
| `reasoning-lesson-plan.md`                | 8 lessons from fallacies to systemic debiasing              |
| `rust-lesson-plan.md`                     | 8 lessons from ownership to lifetimes                       |
| `security-lesson-plan.md`                 | 8 lessons from threat modeling to OWASP Top 10              |
| `specification-lesson-plan.md`            | 8 lessons from decision tables to TLA+ and agent contracts  |
| `system-design-lesson-plan.md`            | 8 lessons from single server to distributed                 |
| `technical-writing-lesson-plan.md`        | 8 lessons on clarity, structure, audience                   |
| `tmux-lesson-plan.md`                     | 8 lessons from basics to scripting, with projects           |
| `typescript-lesson-plan.md`               | 8 lessons from types to advanced patterns                   |

## Commands

```bash
make lint      # Run markdownlint and vale
make format    # Format with prettier
make fix       # Format then lint
make sync      # Download vale style packages
make setup     # Install git hooks
make new       # Create new guide (NAME=foo TYPE=how|why|learn)
```
