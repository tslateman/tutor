# tmux Cheat Sheet

The default prefix key is `Ctrl+b` (shown as `C-b` below).

## Sessions

### Command Line

| Command                     | Description             |
| --------------------------- | ----------------------- |
| `tmux`                      | Start new session       |
| `tmux new -s name`          | Start named session     |
| `tmux ls`                   | List sessions           |
| `tmux attach`               | Attach to last session  |
| `tmux attach -t name`       | Attach to named session |
| `tmux kill-session -t name` | Kill session            |
| `tmux kill-server`          | Kill all sessions       |

### Inside tmux

| Keybinding | Description             |
| ---------- | ----------------------- |
| `C-b d`    | Detach from session     |
| `C-b $`    | Rename session          |
| `C-b s`    | List/switch sessions    |
| `C-b (`    | Previous session        |
| `C-b )`    | Next session            |
| `C-b L`    | Last (previous) session |

## Windows (Tabs)

| Keybinding | Description                  |
| ---------- | ---------------------------- |
| `C-b c`    | Create new window            |
| `C-b ,`    | Rename current window        |
| `C-b &`    | Close current window         |
| `C-b w`    | List windows (interactive)   |
| `C-b n`    | Next window                  |
| `C-b p`    | Previous window              |
| `C-b l`    | Last (toggle) window         |
| `C-b 0-9`  | Switch to window 0-9         |
| `C-b '`    | Switch to window by number   |
| `C-b .`    | Move window to another index |
| `C-b f`    | Find window by name          |

## Panes (Splits)

### Creating Panes

| Keybinding | Description                     |
| ---------- | ------------------------------- |
| `C-b %`    | Split horizontally (left/right) |
| `C-b "`    | Split vertically (top/bottom)   |

### Navigating Panes

| Keybinding  | Description               |
| ----------- | ------------------------- |
| `C-b ←↑↓→`  | Move to pane in direction |
| `C-b o`     | Cycle through panes       |
| `C-b ;`     | Toggle last active pane   |
| `C-b q`     | Show pane numbers         |
| `C-b q 0-9` | Switch to pane by number  |

### Resizing Panes

| Keybinding   | Description                   |
| ------------ | ----------------------------- |
| `C-b C-←↑↓→` | Resize pane (small increment) |
| `C-b M-←↑↓→` | Resize pane (large increment) |
| `C-b z`      | Toggle pane zoom (fullscreen) |
| `C-b !`      | Convert pane to window        |

### Pane Layouts

| Keybinding  | Description           |
| ----------- | --------------------- |
| `C-b Space` | Cycle through layouts |
| `C-b M-1`   | Even horizontal       |
| `C-b M-2`   | Even vertical         |
| `C-b M-3`   | Main horizontal       |
| `C-b M-4`   | Main vertical         |
| `C-b M-5`   | Tiled                 |

### Other Pane Operations

| Keybinding | Description                   |
| ---------- | ----------------------------- |
| `C-b x`    | Kill pane (with confirmation) |
| `C-b {`    | Swap pane with previous       |
| `C-b }`    | Swap pane with next           |
| `C-b C-o`  | Rotate panes forward          |
| `C-b M-o`  | Rotate panes backward         |

## Copy Mode

| Keybinding | Description            |
| ---------- | ---------------------- |
| `C-b [`    | Enter copy mode        |
| `C-b ]`    | Paste buffer           |
| `C-b =`    | Choose buffer to paste |
| `C-b #`    | List buffers           |
| `q`        | Exit copy mode         |

### In Copy Mode (vi keys)

| Keybinding | Description                  |
| ---------- | ---------------------------- |
| `Space`    | Start selection              |
| `Enter`    | Copy selection and exit      |
| `Escape`   | Clear selection              |
| `v`        | Begin selection (if vi-copy) |
| `y`        | Yank selection (if vi-copy)  |
| `/`        | Search forward               |
| `?`        | Search backward              |
| `n`        | Next search result           |
| `N`        | Previous search result       |
| `g`        | Go to top                    |
| `G`        | Go to bottom                 |
| `h j k l`  | Move cursor                  |
| `w b`      | Word forward/backward        |
| `0 $`      | Start/end of line            |
| `C-u C-d`  | Half page up/down            |
| `C-b C-f`  | Full page up/down            |

## Command Mode

| Keybinding | Description        |
| ---------- | ------------------ |
| `C-b :`    | Enter command mode |

### Useful Commands

```bash
# In command mode (C-b :)
source-file ~/.tmux.conf      # Reload config
list-keys                     # List all keybindings
list-commands                 # List all commands
display-message "text"        # Show message
set -g option value           # Set global option
setw -g option value          # Set window option

# Pane operations
swap-pane -s 0 -t 1           # Swap panes
join-pane -s 1 -t 0           # Join pane from window 1
break-pane                    # Move pane to new window

# Sync panes (type in all panes simultaneously)
setw synchronize-panes on
setw synchronize-panes off
```

## Configuration (~/.tmux.conf)

```bash
# Change prefix to C-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse
set -g mouse on

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# Vi mode
setw -g mode-keys vi

# Better splits (| and -)
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes with vim keys
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Quick reload
bind r source-file ~/.tmux.conf \; display "Reloaded!"

# Don't rename windows automatically
set -g allow-rename off

# Increase history limit
set -g history-limit 50000

# Faster escape time (for vim)
set -sg escape-time 0

# 256 color support
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Status bar
set -g status-position top
set -g status-style 'bg=#333333 fg=#ffffff'
set -g status-left '#[fg=green]#S '
set -g status-right '%H:%M %d-%b'

# Active window
setw -g window-status-current-style 'fg=black bg=white'

# Pane borders
set -g pane-border-style 'fg=#444444'
set -g pane-active-border-style 'fg=#00ff00'
```

## Scripting

### Create session with windows and panes

```bash
#!/bin/bash
SESSION="dev"

# Create session with first window
tmux new-session -d -s $SESSION -n "editor"

# Create additional windows
tmux new-window -t $SESSION -n "server"
tmux new-window -t $SESSION -n "logs"

# Split the editor window
tmux select-window -t $SESSION:editor
tmux split-window -h
tmux split-window -v

# Run commands in panes
tmux send-keys -t $SESSION:editor.0 'nvim' C-m
tmux send-keys -t $SESSION:server 'npm run dev' C-m
tmux send-keys -t $SESSION:logs 'tail -f /var/log/app.log' C-m

# Attach to session
tmux attach -t $SESSION
```

### Targeting windows and panes

```bash
# Format: session:window.pane
tmux send-keys -t mysession:0.1 'ls' C-m
tmux select-window -t mysession:editor
tmux select-pane -t mysession:0.2
```

## Useful Tricks

### Send command to all panes

```bash
# Toggle sync
C-b : setw synchronize-panes on
# Type command (appears in all panes)
# Toggle off
C-b : setw synchronize-panes off
```

### Save pane output to file

```bash
C-b : capture-pane -S -3000
C-b : save-buffer ~/tmux.log
```

### Pipe pane output

```bash
C-b : pipe-pane -o 'cat >> ~/output.log'
```

### Clear pane history

```bash
C-b : clear-history
```

### Show all keybindings

```bash
tmux list-keys
tmux list-keys | grep split  # Filter
```

## Quick Reference

| Task             | Command               |
| ---------------- | --------------------- |
| New session      | `tmux new -s name`    |
| Attach           | `tmux attach -t name` |
| Detach           | `C-b d`               |
| New window       | `C-b c`               |
| Split horizontal | `C-b %`               |
| Split vertical   | `C-b "`               |
| Navigate panes   | `C-b arrows`          |
| Zoom pane        | `C-b z`               |
| Kill pane        | `C-b x`               |
| Copy mode        | `C-b [`               |
| Paste            | `C-b ]`               |
| Command mode     | `C-b :`               |
| List sessions    | `C-b s`               |
| List windows     | `C-b w`               |

## See Also

- [tmux Lesson Plan](../learn/tmux-lesson-plan.md) — 8 lessons from basics to
  scripting
- [Terminal Emulators](terminal-emulators.md) — iTerm2 vs Ghostty, tmux -CC
  integration
- [Agent Orchestration](agent-orchestration.md) — tmux for multi-agent sessions
- [Shell](shell.md) — Scripting patterns for tmux automation
