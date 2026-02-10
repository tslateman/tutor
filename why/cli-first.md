# CLI-First

Why some developers route their entire workflow through the terminal — and how
to get there without burning out.

## Why Bother

**Composability.** GUI tools are closed boxes. CLI tools connect with `|`. A
file manager, a fuzzy finder, and a text editor become a single workflow when
they share stdin/stdout. See [CLI Pipelines](../how/cli-pipelines.md).

**Speed.** Keystrokes are faster than mouse travel. Not marginally — the
difference compounds across hundreds of daily actions. A keyboard-driven
developer doesn't context-switch between pointing and typing.

**Reproducibility.** A shell command is a record of what happened. A sequence of
clicks is not. Dotfiles turn your entire environment into a version-controlled,
portable artifact.

**Remote-friendliness.** SSH gives you your full environment on any machine. GUI
tools stay on the machine with the display. tmux makes that session persistent.

**Focus.** A terminal is a text interface. No notification badges, no sidebars,
no distracting chrome. The tool you're using fills the screen.

## The Core Stack

Four tools compose into a full working environment:

| Layer        | Tool                                                | Role                                   |
| ------------ | --------------------------------------------------- | -------------------------------------- |
| Terminal     | [Ghostty](../learn/ghostty-lesson-plan.md) / iTerm2 | GPU rendering, splits, native UI       |
| Multiplexer  | [tmux](../how/tmux.md)                              | Session persistence, remote splits     |
| Editor       | [Neovim](../how/neovim.md)                          | Code editing, LSP, integrated terminal |
| Fuzzy finder | fzf                                                 | Interactive selection for any list     |

Everything else builds on top of these four.

## CLI Replacements

The question isn't "can CLI do X?" — it's "what do people actually use?"

### Files and Navigation

| Instead of    | Use                  | Why                                             |
| ------------- | -------------------- | ----------------------------------------------- |
| Finder        | **yazi**             | Async I/O, image previews, tabs, Lua extensible |
| Spotlight     | **fzf** / **zoxide** | `fzf` for files, `zoxide` for frecent dirs      |
| Directory nav | **zoxide**           | `z project` jumps to ~/dev/project              |

```bash
brew install yazi fzf zoxide
```

### Git

| Instead of     | Use         | Why                                     |
| -------------- | ----------- | --------------------------------------- |
| GitKraken, etc | **lazygit** | Full TUI: stage hunks, rebase, resolve  |
| git log viewer | **tig**     | ncurses browser for log, diff, blame    |
| GitHub UI      | **gh**      | PRs, issues, releases from the terminal |

```bash
brew install lazygit tig gh
```

See [Git Cheatsheet](../how/git.md) for the underlying commands.

### Development

| Instead of            | Use                   | Why                              |
| --------------------- | --------------------- | -------------------------------- |
| Docker Desktop        | **lazydocker**        | Container/image TUI              |
| Kubernetes Dashboard  | **k9s**               | Cluster management TUI           |
| DB GUI (TablePlus)    | **psql** / cli        | Direct SQL, scriptable           |
| REST client (Postman) | **curl** / **httpie** | Scriptable, version-controllable |

```bash
brew install lazydocker k9s httpie
```

### Modern Core Utilities

Rust rewrites of Unix classics — faster, friendlier defaults, respects
`.gitignore`.

| Classic | Replacement | Improvement                              |
| ------- | ----------- | ---------------------------------------- |
| `grep`  | **ripgrep** | 10-100x faster, ignores binary/gitignore |
| `find`  | **fd**      | Intuitive syntax, colored output         |
| `cat`   | **bat**     | Syntax highlighting, line numbers, git   |
| `ls`    | **eza**     | Icons, tree view, git status column      |
| `cd`    | **zoxide**  | Frecency-ranked directory jumping        |
| `diff`  | **delta**   | Syntax-highlighted git diffs             |

```bash
brew install ripgrep fd bat eza zoxide git-delta
```

### Reading and Writing

| Instead of   | Use                   | Why                                    |
| ------------ | --------------------- | -------------------------------------- |
| Notion       | **Neovim** + markdown | Plain text, version-controlled         |
| PDF viewer   | less / **glow**       | Markdown rendering in terminal         |
| Spreadsheets | **visidata**          | Tabular data viewer/editor, any format |

```bash
brew install glow visidata
```

### System

| Instead of       | Use        | Why                               |
| ---------------- | ---------- | --------------------------------- |
| Activity Monitor | **btop**   | Beautiful, detailed, keyboard-nav |
| System Prefs     | `defaults` | Scriptable macOS configuration    |

```bash
brew install btop
```

## Window Management

A CLI-first workflow needs keyboard-driven window placement. On macOS:

**AeroSpace** (recommended) — i3-like tiling. No SIP disable required.

```bash
brew install --cask nikitabobko/tap/aerospace
```

Core concepts:

- Workspaces: `Alt+1` through `Alt+9`
- Move window to workspace: `Alt+Shift+1` through `Alt+Shift+9`
- Split direction: `Alt+/` (toggle horizontal/vertical)
- Focus: `Alt+h/j/k/l`
- Move: `Alt+Shift+h/j/k/l`

The keybindings mirror vim and tmux navigation — `h/j/k/l` everywhere.

**Alternatives:**

- **yabai** — More powerful, but requires SIP disable for full features
- **Amethyst** — Simpler, fewer features, no config file needed

## Where CLI Is Genuinely Worse

Honesty matters. Don't force these into a terminal:

- **Image/video editing.** GIMP and FFmpeg exist but nobody prefers them for
  creative work.
- **Web browsing.** w3m and lynx are novelties, not workflows.
- **Spreadsheets with formulas.** visidata views data well but isn't Excel.
- **Presentations.** Slides need visual layout tools.
- **Video calls.** Obviously.

The CLI-first mindset isn't "never use a GUI." It's "default to the terminal and
reach for a GUI only when the terminal genuinely can't do it."

## Building the Habit

Going cold turkey fails. Transition gradually:

### Week 1-2: Replace one tool

Pick the GUI tool you use most for something the terminal does well. Usually
git. Install lazygit. Use it for all git operations for two weeks.

### Week 3-4: Add navigation

Install fzf and zoxide. Stop clicking through Finder to find files. Use `Ctrl+T`
(fzf) and `z dirname` (zoxide) instead.

### Month 2: Window management

Install AeroSpace. Learn `Alt+h/j/k/l` for focus and `Alt+Shift+number` for
workspaces. Stop dragging windows.

### Month 3: Fill gaps

Replace remaining GUI tools one at a time. Each replacement takes a few days of
friction, then becomes faster than what it replaced.

### The test

You'll know the transition is working when you SSH into a remote machine and
feel at home. Your muscle memory works everywhere because it's all the same
tools.

## Dotfiles

A CLI-first workflow lives or dies by its dotfiles. Version control them.

```text
~/.config/
├── aerospace/       # window manager
│   └── aerospace.toml
├── ghostty/         # terminal
│   └── config
├── nvim/            # editor
│   └── init.lua
├── tmux/            # multiplexer
│   └── tmux.conf
├── bat/             # cat replacement
│   └── config
└── git/             # git
    └── config
```

```bash
# Symlink from a git repo
git init ~/dotfiles
# Move configs there, symlink back
ln -s ~/dotfiles/ghostty ~/.config/ghostty
```

New machine setup becomes: clone the repo, run the symlink script, install
packages. Ten minutes to a full environment.

## See Also

- [CLI Pipelines](../how/cli-pipelines.md) — Pipes, substitution, xargs, fzf
- [Shell Scripting](../how/shell.md) — Variables, functions, control flow
- [Unix CLI](../how/unix.md) — Core commands
- [tmux](../how/tmux.md) — Multiplexer reference
- [Neovim](../how/neovim.md) — Editor reference
- [Ghostty Lesson Plan](../learn/ghostty-lesson-plan.md) — Terminal emulator
- [Terminal Emulators](../how/terminal-emulators.md) — iTerm2 vs Ghostty
- [awesome-tuis](https://github.com/rothgar/awesome-tuis) — Community list of
  TUI applications
