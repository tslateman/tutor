# tmux Lesson Plan

A progressive curriculum to master tmux through hands-on practice.

## Lesson 1: First Contact

**Goal:** Understand what tmux does and run your first session.

### Concepts

tmux is a terminal multiplexer. It lets you:

- Run multiple terminals in one window
- Detach sessions and reconnect later (survives SSH disconnects)
- Split your screen into panes

### Exercises

1. **Start and exit tmux**

   ```bash
   tmux           # Enter tmux
   exit           # Leave tmux (closes session)
   ```

2. **Create a named session**

   ```bash
   tmux new -s practice
   ```

3. **Detach and reattach**

   ```bash
   # Inside tmux, press: C-b d (Ctrl+b, then d)
   # You're back in your normal shell. The session lives on.

   tmux ls                    # See your session
   tmux attach -t practice    # Reconnect
   ```

4. **Kill the session**

   ```bash
   tmux kill-session -t practice
   ```

### Checkpoint

You understand the session lifecycle: create → detach → attach → kill.

---

## Lesson 2: Windows

**Goal:** Manage multiple terminals within one session.

### Concepts

Windows are like browser tabs. Each window has its own shell. You see one window
at a time.

### Exercises

1. **Create a session and add windows**

   ```bash
   tmux new -s dev
   # C-b c    Create window
   # C-b c    Create another
   ```

2. **Navigate windows**

   ```bash
   # C-b n    Next window
   # C-b p    Previous window
   # C-b 0    Go to window 0
   # C-b 1    Go to window 1
   # C-b w    Interactive window list
   ```

3. **Name your windows**

   ```bash
   # C-b ,    Rename current window
   # Type: editor
   ```

4. **Close a window**

   ```bash
   # C-b &    Kill window (confirms first)
   # Or just type: exit
   ```

### Checkpoint

Create 3 windows named "editor", "server", "logs". Jump between them by number.

---

## Lesson 3: Panes

**Goal:** Split windows into multiple views.

### Concepts

Panes divide a window into sections. All panes in a window display
simultaneously.

- `C-b %` splits left/right (think: % has two circles side by side)
- `C-b "` splits top/bottom (think: " has two dots stacked)

### Exercises

1. **Split and navigate**

   ```bash
   # Start fresh
   tmux new -s panes

   # C-b %      Split vertically (left/right)
   # C-b "      Split horizontally (top/bottom)
   # C-b ←↑↓→   Move between panes
   ```

2. **Zoom a pane**

   ```bash
   # C-b z     Toggle fullscreen on current pane
   # C-b z     Toggle back
   ```

3. **Close panes**

   ```bash
   # C-b x     Kill pane (with confirmation)
   # Or: exit
   ```

4. **Resize panes**

   ```bash
   # C-b C-←↑↓→    Resize (small steps)
   # C-b M-←↑↓→    Resize (big steps)
   ```

### Checkpoint

Create this layout:

```text
+--------+--------+
|        |   B    |
|   A    +--------+
|        |   C    |
+--------+--------+
```

Start in window → split right → go to right pane → split down.

---

## Lesson 4: Copy Mode

**Goal:** Scroll history and copy text.

### Concepts

Terminals lose scrollback when they fill. Copy mode lets you scroll, search, and
yank text.

### Exercises

1. **Generate scrollback**

   ```bash
   tmux new -s copy
   seq 1 500          # Print 500 lines
   ```

2. **Enter copy mode and scroll**

   ```bash
   # C-b [         Enter copy mode
   # ↑ ↓           Scroll line by line
   # C-u C-d       Scroll half pages
   # g             Go to top
   # G             Go to bottom
   # q             Exit copy mode
   ```

3. **Search**

   ```bash
   # C-b [         Enter copy mode
   # /250          Search forward for "250"
   # n             Next match
   # N             Previous match
   ```

4. **Copy and paste**

   ```bash
   # C-b [         Enter copy mode
   # Space         Start selection
   # (move cursor)
   # Enter         Copy and exit
   # C-b ]         Paste
   ```

### Checkpoint

Copy lines 100-110 from your scrollback and paste them.

---

## Lesson 5: Configuration

**Goal:** Customize tmux to your preferences.

### Exercises

1. **Create a config file**

   ```bash
   touch ~/.tmux.conf
   ```

2. **Add basic improvements**

   ```bash
   # ~/.tmux.conf

   # Start numbering at 1 (easier to reach)
   set -g base-index 1
   setw -g pane-base-index 1

   # Enable mouse
   set -g mouse on

   # Vi mode in copy mode
   setw -g mode-keys vi

   # Increase history
   set -g history-limit 50000
   ```

3. **Reload config**

   ```bash
   # Inside tmux:
   # C-b :
   # source-file ~/.tmux.conf
   ```

4. **Add intuitive splits**

   ```bash
   # ~/.tmux.conf (append)

   # Split with | and -
   bind | split-window -h -c "#{pane_current_path}"
   bind - split-window -v -c "#{pane_current_path}"
   ```

### Checkpoint

Your config loads. `C-b |` splits horizontally. Mouse scrolling works.

---

## Lesson 6: Session Workflow

**Goal:** Use sessions for project organization.

### Concepts

One session per project keeps contexts separate. Detach from one, attach to
another.

### Exercises

1. **Create project sessions**

   ```bash
   tmux new -s project-a -d    # -d = detached
   tmux new -s project-b -d
   tmux ls                     # See both
   ```

2. **Switch sessions**

   ```bash
   tmux attach -t project-a
   # C-b s         List sessions (interactive)
   # C-b )         Next session
   # C-b (         Previous session
   ```

3. **Session within session (avoid this)**

   ```bash
   # If you see "sessions should be nested..." you're in tmux already.
   # Use C-b s to switch, don't nest.
   ```

### Checkpoint

Maintain 2 project sessions. Switch between them without detaching.

---

## Lesson 7: Scripting

**Goal:** Automate your development environment.

### Exercises

1. **Create a dev script**

   ```bash
   #!/bin/bash
   # ~/bin/dev-session.sh

   SESSION="dev"

   # Exit if session exists
   tmux has-session -t $SESSION 2>/dev/null && {
       tmux attach -t $SESSION
       exit 0
   }

   # Create session with editor window
   tmux new-session -d -s $SESSION -n "editor"
   tmux send-keys -t $SESSION:editor "nvim ." C-m

   # Create server window
   tmux new-window -t $SESSION -n "server"
   tmux send-keys -t $SESSION:server "npm run dev" C-m

   # Create split window for git and tests
   tmux new-window -t $SESSION -n "tools"
   tmux split-window -h -t $SESSION:tools
   tmux send-keys -t $SESSION:tools.0 "git status" C-m

   # Go back to editor
   tmux select-window -t $SESSION:editor

   # Attach
   tmux attach -t $SESSION
   ```

2. **Make it executable**

   ```bash
   chmod +x ~/bin/dev-session.sh
   ```

3. **Use target syntax**

   ```bash
   # session:window.pane
   tmux send-keys -t dev:editor.0 "echo hello" C-m
   tmux select-pane -t dev:tools.1
   ```

### Checkpoint

Run your script. It creates your ideal workspace in one command.

---

## Lesson 8: Advanced Tricks

**Goal:** Power user techniques.

### Exercises

1. **Synchronize panes** (run command on all panes)

   ```bash
   # Create 3 panes
   # C-b :
   # setw synchronize-panes on
   # Type a command - it appears in all panes
   # setw synchronize-panes off
   ```

2. **Capture pane to file**

   ```bash
   # C-b :
   # capture-pane -S -3000
   # save-buffer ~/debug.log
   ```

3. **Break pane to window**

   ```bash
   # C-b !    Move current pane to its own window
   ```

4. **Join windows**

   ```bash
   # C-b :
   # join-pane -s 2 -t 1    # Move window 2 into window 1 as pane
   ```

5. **Pipe pane output**

   ```bash
   # C-b :
   # pipe-pane -o 'cat >> ~/output.log'
   # (all output goes to file until you run pipe-pane again)
   ```

### Checkpoint

Sync 3 panes. Run `uptime` in all of them simultaneously.

---

## Practice Projects

### Project 1: Monitoring Dashboard

Create a session with:

- Window 1: `htop`
- Window 2: Split into 4 panes showing different log files

### Project 2: Dev Environment

Script that creates:

- Window "code": editor
- Window "run": split with server and file watcher
- Window "test": test runner
- Window "git": git status and lazygit

### Project 3: SSH Resilience

SSH to a server, start tmux, run a long job, disconnect intentionally,
reconnect, verify job continued.

---

## Key Bindings Summary

| Stage    | Must Know                                          |
| -------- | -------------------------------------------------- |
| Beginner | `C-b d` `C-b c` `C-b n` `C-b %` `C-b "` `C-b ←↑↓→` |
| Daily    | `C-b z` `C-b [` `C-b s` `C-b w` `C-b ,` `C-b x`    |
| Power    | `C-b :` `C-b !` `C-b &` sync-panes, scripting      |
