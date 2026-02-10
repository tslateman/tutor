# Ghostty Lesson Plan

A progressive curriculum to master Ghostty through hands-on practice.

## Lesson 1: Installation and First Launch

**Goal:** Install Ghostty and understand what makes it different.

### Concepts

Ghostty is a GPU-accelerated terminal emulator by Mitchell Hashimoto. It ships
with sensible defaults: JetBrains Mono font, built-in Nerd Font symbols,
hundreds of themes, and automatic shell integration. No config file required to
start.

Three things set it apart:

- **Native UI** — Swift/AppKit on macOS, GTK4 on Linux (not custom widgets)
- **GPU rendering** — Metal on macOS, OpenGL on Linux
- **Zero-config defaults** — usable immediately without a config file

### Exercises

1. **Install Ghostty**

   ```bash
   # macOS (Homebrew)
   brew install --cask ghostty

   # macOS (direct download)
   # Visit ghostty.org/download for a signed DMG

   # Arch Linux
   sudo pacman -S ghostty

   # NixOS
   # Available via nixpkgs
   ```

2. **Launch and explore defaults**

   ```bash
   # Open Ghostty from your Applications folder or launcher
   # Notice: JetBrains Mono font, no config needed

   echo "Hello from Ghostty"
   ```

3. **Verify GPU rendering**

   ```bash
   # Open the terminal inspector
   # macOS: Cmd+Option+I
   # Linux: Ctrl+Shift+I

   # Look at the "Renderer" section — it shows Metal or OpenGL
   ```

4. **Check the version**

   ```bash
   ghostty --version
   ```

5. **List default keybindings**

   ```bash
   ghostty +list-keybinds --default
   ```

### Checkpoint

Ghostty is running. The inspector shows your GPU backend. You can read the
default keybindings.

---

## Lesson 2: Configuration Basics

**Goal:** Create a config file and customize appearance.

### Concepts

Ghostty uses a simple key-value config file. Every option also works as a CLI
flag. No config file is required — create one only when you want to change
something.

Config location:

- `~/.config/ghostty/config` (XDG default, works on macOS and Linux)
- `~/Library/Application Support/com.mitchellh.ghostty/config` (macOS
  alternative)

### Exercises

1. **Create a config file**

   ```bash
   mkdir -p ~/.config/ghostty
   touch ~/.config/ghostty/config
   ```

2. **Set font and size**

   ```bash
   # ~/.config/ghostty/config

   font-family = JetBrains Mono
   font-size = 14
   ```

3. **Apply a theme**

   ```bash
   # Ghostty ships hundreds of themes. Pick one:
   theme = catppuccin-mocha

   # Or try: dracula, gruvbox-dark, tokyo-night, nord
   # List available themes:
   ghostty +list-themes
   ```

4. **Adjust transparency**

   ```bash
   background-opacity = 0.95
   ```

5. **Reload without restarting**

   ```bash
   # macOS: Cmd+Shift+,
   # Linux: Ctrl+Shift+,

   # Changes apply instantly to the current terminal
   ```

6. **Test config via CLI flags**

   ```bash
   # Override any config option from the command line
   ghostty --font-size=18 --theme=dracula
   ```

7. **Split config across files**

   ```bash
   # ~/.config/ghostty/config
   config-file = themes/my-overrides

   # ~/.config/ghostty/themes/my-overrides
   bold-color = #ff79c6
   cursor-style = bar
   ```

### Checkpoint

Your config loads on launch. `Cmd+Shift+,` (or `Ctrl+Shift+,`) reloads changes.
You can switch themes without restarting.

---

## Lesson 3: Tabs and Windows

**Goal:** Manage multiple terminals with tabs and windows.

### Concepts

Ghostty renders tabs and windows using native platform UI — real macOS tabs,
real GTK tabs. They look and behave like tabs in any other native app.

### Exercises

1. **Create and navigate tabs**

   ```bash
   # macOS                      Linux
   # Cmd+T       New tab        Ctrl+Shift+T
   # Cmd+Shift+] Next tab       Ctrl+Page_Down
   # Cmd+Shift+[ Previous tab   Ctrl+Page_Up
   # Cmd+1..9    Go to tab N    Alt+1..9
   ```

2. **Move tabs**

   ```bash
   # Drag tabs to reorder (native drag-and-drop)
   # Or use keybindings:
   # macOS: Cmd+Shift+Left/Right (move tab position)
   ```

3. **Open new windows**

   ```bash
   # macOS: Cmd+N
   # Linux: Ctrl+Shift+N
   ```

4. **Close tabs**

   ```bash
   # macOS: Cmd+W
   # Linux: Ctrl+Shift+W

   # Smart close: no confirmation when at an idle prompt
   # Confirmation appears only if a command is running
   ```

5. **Recover a closed tab (macOS)**

   ```bash
   # Cmd+Z within 5 seconds of closing — undo the close
   # This is unique to Ghostty
   ```

### Checkpoint

Open 4 tabs. Jump to tab 3 by number. Close one. On macOS, undo the close with
`Cmd+Z`.

---

## Lesson 4: Split Panes

**Goal:** Divide tabs into multiple views.

### Concepts

Splits divide a tab into panes. Each pane runs its own shell. New splits inherit
the working directory of the focused pane (via shell integration).

### Exercises

1. **Create splits**

   ```bash
   # macOS                          Linux
   # Cmd+D         Split right      Ctrl+Shift+D (or Enter)
   # Cmd+Shift+D   Split down       Ctrl+Shift+O (or -)
   ```

2. **Navigate between splits**

   ```bash
   # macOS                          Linux
   # Cmd+Option+Arrow  Directional  Ctrl+Shift+Arrow (or Alt+Arrow)
   # Cmd+]             Next split
   # Cmd+[             Previous
   ```

3. **Zoom a split**

   ```bash
   # macOS: Cmd+Shift+Enter (toggle zoom)
   # Linux: Ctrl+Shift+Enter

   # Zoomed pane fills the tab. Toggle again to restore.
   ```

4. **Equalize split sizes**

   ```bash
   # macOS: Cmd+Shift+= (equalize)
   # Linux: Ctrl+Shift+=
   ```

5. **Resize splits**

   ```bash
   # macOS: Cmd+Ctrl+Arrow keys
   # Linux: Ctrl+Shift+Alt+Arrow keys

   # Or drag the split border with the mouse
   ```

6. **Close a split**

   ```bash
   # macOS: Cmd+W (closes focused pane)
   # Linux: Ctrl+Shift+W
   ```

7. **Build a layout**

   Create this arrangement:

   ```text
   +--------+--------+
   |        |   B    |
   |   A    +--------+
   |        |   C    |
   +--------+--------+
   ```

   Steps: start → split right (B) → split down (C) → navigate back to A.

### Checkpoint

Build the three-pane layout above. Navigate to each pane. Zoom pane C, then
unzoom. Equalize all panes.

---

## Lesson 5: Keybindings

**Goal:** Customize keybindings and use advanced binding features.

### Concepts

Keybindings map a trigger (key combination) to an action. Ghostty supports
modifiers, key sequences (Emacs-style chords), and trigger prefixes that control
scope and consumption.

### Exercises

1. **Bind a simple key**

   ```bash
   # ~/.config/ghostty/config

   # Vim-style split navigation
   keybind = alt+h=goto_split:left
   keybind = alt+j=goto_split:bottom
   keybind = alt+k=goto_split:top
   keybind = alt+l=goto_split:right
   ```

2. **Bind split creation**

   ```bash
   keybind = alt+shift+h=new_split:left
   keybind = alt+shift+j=new_split:down
   keybind = alt+shift+k=new_split:up
   keybind = alt+shift+l=new_split:right
   ```

3. **Use key sequences (Emacs-style)**

   ```bash
   # ctrl+x followed by 2 = split down
   keybind = ctrl+x>2=new_split:down
   # ctrl+x followed by 3 = split right
   keybind = ctrl+x>3=new_split:right
   # ctrl+x followed by 0 = close pane
   keybind = ctrl+x>0=close_surface
   ```

4. **Use trigger prefixes**

   ```bash
   # global: works even when Ghostty is not focused (macOS)
   keybind = global:ctrl+grave_accent=toggle_quick_terminal

   # performable: only consume key if action can succeed
   keybind = performable:cmd+c=copy_to_clipboard

   # unconsumed: run action but still send key to program
   keybind = unconsumed:ctrl+a=select_all
   ```

5. **Send literal text**

   ```bash
   # Send raw text or escape sequences
   keybind = ctrl+shift+u=text:Hello, World!
   keybind = alt+backspace=text:\x15   # Send Ctrl+U (kill line)
   keybind = ctrl+shift+e=esc:d        # Send Alt+D (kill word)
   ```

6. **Unbind and ignore**

   ```bash
   # Remove a default binding (key passes through to program)
   keybind = ctrl+shift+n=unbind

   # Swallow the key entirely (neither Ghostty nor program sees it)
   keybind = ctrl+shift+q=ignore
   ```

7. **Discover actions**

   ```bash
   # List all available actions
   ghostty +list-keybinds --default | sort

   # Open the command palette to search actions interactively
   # macOS: Cmd+Shift+P
   # Linux: Ctrl+Shift+P
   ```

### Checkpoint

Add Vim-style split navigation. Create a key sequence `ctrl+x>1` that closes all
other splits (action: `close_all_splits`). Verify with the command palette.

---

## Lesson 6: Shell Integration

**Goal:** Use Ghostty's automatic shell integration features.

### Concepts

Ghostty injects shell integration scripts automatically for bash, zsh, fish, and
elvish. No manual setup. These scripts mark prompts, track directories, and
enable navigation features.

### Exercises

1. **Verify integration is active**

   ```bash
   # Run a few commands, then check the inspector
   ls
   echo "test"
   date

   # macOS: Cmd+Option+I → look for "Shell Integration: active"
   ```

2. **Jump between prompts**

   ```bash
   # Generate some history
   for i in $(seq 1 20); do echo "Command $i"; done

   # Jump to previous prompt
   # macOS: Cmd+Up
   # Linux: Ctrl+Shift+Up

   # Jump to next prompt
   # macOS: Cmd+Down
   # Linux: Ctrl+Shift+Down
   ```

3. **Select command output**

   ```bash
   ls -la /usr/local/bin

   # Triple-click + modifier to select entire command output
   # macOS: Cmd + triple-click
   # Linux: Ctrl + triple-click
   ```

4. **Click to position cursor**

   ```bash
   # At a prompt, type a long command:
   echo "this is a long command with many words"

   # Alt+Click (macOS: Option+Click) on a word to move cursor there
   # Works only at a prompt, not inside running programs
   ```

5. **New terminals inherit directory**

   ```bash
   cd ~/Projects/my-app

   # Open a new split (Cmd+D or Ctrl+Shift+D)
   # The new pane starts in ~/Projects/my-app
   pwd    # Confirms inherited directory
   ```

6. **Configure integration features**

   ```bash
   # ~/.config/ghostty/config

   # Enable all features (default)
   shell-integration-features = cursor,sudo,title,jump

   # cursor: bar cursor at prompt
   # sudo:   preserve Ghostty terminfo through sudo
   # title:  update window title with command/directory
   # jump:   enable prompt jumping
   ```

7. **Handle SSH gracefully**

   ```bash
   # Ghostty can wrap SSH to preserve terminfo on remote hosts
   # Enable in config:
   shell-integration-features = cursor,sudo,title,jump

   # When SSH fails with terminfo errors, Ghostty falls back to
   # TERM=xterm-256color automatically
   ```

### Checkpoint

Run 10 commands. Jump backward 5 prompts. Triple-click to select one command's
output. Open a split and confirm it inherited your directory.

---

## Lesson 7: Advanced Features

**Goal:** Use custom shaders, the inspector, quick terminal, and command
palette.

### Exercises

1. **Use the command palette**

   ```bash
   # macOS: Cmd+Shift+P
   # Linux: Ctrl+Shift+P

   # Type "split" to find all split-related actions
   # Execute any action without memorizing its keybinding
   ```

2. **Explore the terminal inspector**

   ```bash
   # macOS: Cmd+Option+I
   # Linux: Ctrl+Shift+I

   # Tabs in the inspector:
   # - Input:    Shows keystrokes and how they're encoded
   # - Terminal:  Shows escape sequences and terminal state
   # - Renderer: Shows frame timings and GPU info

   # Type in the terminal and watch the inspector update
   printf "\e[31mRed text\e[0m"
   ```

3. **Set up the quick terminal (macOS)**

   ```bash
   # ~/.config/ghostty/config

   keybind = global:ctrl+grave_accent=toggle_quick_terminal

   # Customize its size (percentage of screen)
   quick-terminal-size = 40%

   # Now Ctrl+` toggles a dropdown terminal from any app
   ```

4. **Apply a custom shader**

   ```bash
   mkdir -p ~/.config/ghostty/shaders

   # Create a simple CRT scanline shader
   cat > ~/.config/ghostty/shaders/crt.glsl << 'SHADER'
   void mainImage(out vec4 fragColor, in vec2 fragCoord) {
       vec2 uv = fragCoord / iResolution.xy;
       vec4 color = texture(iChannel0, uv);
       float scanline = sin(uv.y * iResolution.y * 3.14159) * 0.04;
       color.rgb -= scanline;
       fragColor = color;
   }
   SHADER
   ```

   ```bash
   # ~/.config/ghostty/config
   custom-shader = shaders/crt.glsl

   # Reload config — the shader applies immediately
   # Edit the shader file — changes hot-reload
   ```

5. **Add a background image**

   ```bash
   # ~/.config/ghostty/config
   background-image = ~/Pictures/terminal-bg.png
   background-image-opacity = 0.1
   ```

6. **Toggle fullscreen and window decorations**

   ```bash
   # macOS: Cmd+Ctrl+F (fullscreen)
   # Linux: F11

   # Remove window decorations for a minimal look:
   window-decoration = false
   ```

### Checkpoint

Open the command palette and find "toggle fullscreen". Apply the CRT shader and
verify it hot-reloads when edited. Toggle the quick terminal from another
application.

---

## Lesson 8: Workflow Integration

**Goal:** Integrate Ghostty into your daily development workflow.

### Concepts

Ghostty handles local multiplexing well but does not replace tmux for remote
work. Use Ghostty splits for local tasks; use tmux for persistent remote
sessions.

### Exercises

1. **Build a development layout**

   ```text
   +------------------+----------+
   |                  |  server  |
   |     editor       +----------+
   |                  |   tests  |
   +------------------+----------+
   ```

   ```bash
   # 1. Open Ghostty
   # 2. Split right (Cmd+D / Ctrl+Shift+D)
   # 3. In right pane: split down (Cmd+Shift+D / Ctrl+Shift+O)
   # 4. Navigate to right-top: start your dev server
   # 5. Navigate to right-bottom: run test watcher
   # 6. Navigate to left: open your editor
   ```

2. **Use Ghostty for local, tmux for remote**

   ```bash
   # Local splits for local work — native, fast, GPU-rendered
   # SSH into servers and attach tmux there

   ssh prod-server
   tmux attach -t deploy
   # tmux handles the remote session persistence
   # Ghostty handles the local rendering
   ```

3. **Configure font features for coding**

   ```bash
   # ~/.config/ghostty/config

   # Enable ligatures (JetBrains Mono supports them)
   font-feature = calt
   font-feature = liga

   # Or disable them
   font-feature = -calt
   font-feature = -liga

   # Add a fallback font for CJK or special characters
   font-family = JetBrains Mono
   font-family = Noto Sans CJK
   ```

4. **Set up link handling**

   ```bash
   # Cmd+Click (macOS) or Ctrl+Click (Linux) on URLs to open them
   # Ghostty detects URLs automatically

   echo "https://ghostty.org"
   # Cmd+Click / Ctrl+Click the URL above
   ```

5. **Use selection features**

   ```bash
   # Double-click: select word
   # Triple-click: select line
   # Cmd/Ctrl + triple-click: select entire command output (via shell integration)

   # Selection clears when you start typing (configurable):
   selection-clear-on-typing = true
   ```

6. **Create a complete config**

   ```bash
   # ~/.config/ghostty/config — a practical starting point

   # Appearance
   theme = catppuccin-mocha
   font-family = JetBrains Mono
   font-size = 14
   background-opacity = 0.97
   cursor-style = bar
   window-padding-x = 4
   window-padding-y = 4

   # Shell integration
   shell-integration-features = cursor,sudo,title,jump

   # Splits — Vim-style navigation
   keybind = alt+h=goto_split:left
   keybind = alt+j=goto_split:bottom
   keybind = alt+k=goto_split:top
   keybind = alt+l=goto_split:right
   keybind = alt+shift+d=new_split:down
   keybind = alt+shift+r=new_split:right

   # Quick terminal (macOS)
   keybind = global:ctrl+grave_accent=toggle_quick_terminal
   ```

### Checkpoint

Build the development layout from step 1 using only keyboard shortcuts. Verify
URL click-to-open works. Start from a clean config and build it up with only the
options you need.

---

## Practice Projects

### Project 1: Config from Scratch

Delete your config. Use Ghostty with defaults for a day. Then add back only the
settings you actually missed. Record what you kept and what you didn't need.

### Project 2: Shader Gallery

Find 3 community shaders (search GitHub for "ghostty shaders"). Install them.
Create keybindings to switch between them by swapping the `custom-shader` config
and reloading.

### Project 3: Workflow Audit

Spend a day tracking how you use your terminal. At the end, configure Ghostty to
eliminate your most common friction points: keybindings for frequent actions,
splits for your typical layout, quick terminal for one-off commands.

---

## Key Reference

| Stage    | Must Know                                                             |
| -------- | --------------------------------------------------------------------- |
| Beginner | New tab, close tab, new window, font/theme config                     |
| Splits   | Split right/down, navigate splits, zoom, equalize                     |
| Daily    | Prompt jumping, command palette, config reload, directory inheritance |
| Power    | Key sequences, custom shaders, inspector, quick terminal              |

## See Also

- [Ghostty Documentation](https://ghostty.org/docs) — Official reference
- [Ghostty Config Reference](https://ghostty.org/docs/config/reference) — All
  config options
- [tmux Lesson Plan](tmux-lesson-plan.md) — For remote multiplexing alongside
  Ghostty
