# Tutor

Personal reference for tools, languages, and techniques.

## how/

Commands, syntax, quick reference.

| Topic                           | Description                                         |
| ------------------------------- | --------------------------------------------------- |
| [AI CLI](how/ai-cli.md)         | Claude Code, context files, prompting, verification |
| [Docker](how/docker.md)         | Images, containers, Dockerfile, Compose, networking |
| [Git](how/git.md)               | Commits, branches, merging, rebasing, remotes       |
| [HTTP](how/http.md)             | curl, headers, status codes, REST conventions       |
| [jq](how/jq.md)                 | JSON processing, filters, transforms                |
| [macOS](how/macos.md)           | Homebrew, defaults, Spotlight, launchctl            |
| [Neovim](how/neovim.md)         | LazyVim keybindings, Telescope, code actions        |
| [PostgreSQL](how/postgres.md)   | psql, indexes, window functions, admin              |
| [Python](how/python.md)         | Data structures, comprehensions, typing, async      |
| [Regex](how/regex.md)           | Patterns, quantifiers, groups, lookahead            |
| [Rust](how/rust.md)             | Ownership, borrowing, lifetimes, traits, cargo      |
| [Shell](how/shell.md)           | Scripting patterns, loops, conditionals, functions  |
| [SQL](how/sql.md)               | Joins, CTEs, window functions                       |
| [Testing](how/testing.md)       | pytest, Jest, Go, Rust test runners                 |
| [tmux](how/tmux.md)             | Sessions, windows, panes, copy mode                 |
| [TypeScript](how/typescript.md) | Types, generics, utility types, patterns            |
| [Unix](how/unix.md)             | Shell commands, file ops, text processing, SSH      |

## why/

Mental models, principles, frameworks.

| Topic                                     | Description                                            |
| ----------------------------------------- | ------------------------------------------------------ |
| [Complexity](why/complexity.md)           | Essential vs accidental, techniques, heuristics        |
| [Debugging](why/debugging.md)             | Scientific method, bisection, isolation techniques     |
| [Learning](why/learning.md)               | Retention techniques, spaced repetition, active recall |
| [Problem-solving](why/problem-solving.md) | Polya's method, divide-and-conquer, rubber duck        |
| [Thinking](why/thinking.md)               | Mental models, systems thinking, asking good questions |

## learn/

Progressive lesson plans with exercises.

| Topic                                                       | Description                               |
| ----------------------------------------------------------- | ----------------------------------------- |
| [Git](learn/git-lesson-plan.md)                             | 8 lessons from commits to workflows       |
| [Go](learn/golang-lesson-plan.md)                           | 8 lessons from basics to concurrency      |
| [Python](learn/python-lesson-plan.md)                       | 8 lessons from basics to async            |
| [Rust](learn/rust-lesson-plan.md)                           | 8 lessons from ownership to lifetimes     |
| [Technical Writing](learn/technical-writing-lesson-plan.md) | 8 lessons on clarity, structure, audience |
| [tmux](learn/tmux-lesson-plan.md)                           | 8 lessons from basics to scripting        |
| [TypeScript](learn/typescript-lesson-plan.md)               | 8 lessons from types to advanced patterns |

## Setup

```bash
brew install markdownlint-cli prettier vale lychee
make sync     # Download vale style packages
make setup    # Install git hooks
```

## Commands

```bash
make help     # Show all commands
make lint     # Check style (markdownlint + vale + links)
make format   # Format with prettier
make fix      # Format then lint
make new      # Create new guide (NAME=foo TYPE=how|why)
make prose    # Review prose with Claude (Strunk's rules)
```

The `make prose` command uses the bundled
[elements-of-style](https://github.com/obra/the-elements-of-style) Claude Code
plugin to review writing with Strunk's rules.
