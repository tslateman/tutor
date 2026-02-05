# Tutor

Personal reference for tools, languages, and techniques.

## Cheatsheets

| Topic                                   | Description                                            |
| --------------------------------------- | ------------------------------------------------------ |
| [Docker](cheatsheets/docker.md)         | Images, containers, Dockerfile, Compose, networking    |
| [Git](cheatsheets/git.md)               | Commits, branches, merging, rebasing, remotes          |
| [jq](cheatsheets/jq.md)                 | JSON processing, filters, transforms                   |
| [Learning](cheatsheets/learning.md)     | Retention techniques, spaced repetition, active recall |
| [macOS](cheatsheets/macos.md)           | Homebrew, defaults, Spotlight, launchctl               |
| [Neovim](cheatsheets/neovim.md)         | LazyVim keybindings, Telescope, code actions           |
| [PostgreSQL](cheatsheets/postgres.md)   | psql, indexes, window functions, admin                 |
| [Python](cheatsheets/python.md)         | Data structures, comprehensions, typing, async         |
| [Regex](cheatsheets/regex.md)           | Patterns, quantifiers, groups, lookahead               |
| [SQL](cheatsheets/sql.md)               | Joins, CTEs, window functions                          |
| [Thinking](cheatsheets/thinking.md)     | Mental models, systems thinking, asking good questions |
| [tmux](cheatsheets/tmux.md)             | Sessions, windows, panes, copy mode                    |
| [TypeScript](cheatsheets/typescript.md) | Types, generics, utility types, patterns               |
| [Unix](cheatsheets/unix.md)             | Shell commands, file ops, text processing, SSH         |

## Setup

```bash
brew install markdownlint-cli prettier vale
make sync     # Download vale style packages
make setup    # Install git hooks
```

## Commands

```bash
make help     # Show all commands
make lint     # Check style (markdownlint + vale)
make format   # Format with prettier
make fix      # Format then lint
make prose    # Review prose with Claude (Strunk's rules)
```

The `make prose` command uses the bundled
[elements-of-style](https://github.com/obra/the-elements-of-style) Claude Code
plugin to review writing with Strunk's rules.
