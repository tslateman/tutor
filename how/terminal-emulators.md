# Terminal Emulators: iTerm2 vs Ghostty

A comparison of the two leading macOS terminal emulators to help you choose — or
understand what you gain and lose when switching.

## At a Glance

| Dimension         | iTerm2               | Ghostty                               |
| ----------------- | -------------------- | ------------------------------------- |
| Author            | George Nachman       | Mitchell Hashimoto                    |
| Language          | Objective-C          | Zig                                   |
| Rendering         | CPU                  | GPU (Metal on macOS, OpenGL on Linux) |
| Platform          | macOS only           | macOS + Linux                         |
| UI toolkit        | Cocoa                | SwiftUI (macOS), GTK4 (Linux)         |
| Configuration     | GUI preferences pane | Plain text config file                |
| Memory under load | ~207 MB              | ~129 MB                               |
| Startup speed     | Perceptible delay    | Near-instant                          |
| First release     | 2003                 | 2024                                  |

## Where iTerm2 Wins

**Feature depth.** Two decades of accumulated features: profiles, triggers,
smart selection, shell integration, badges, password manager, broadcast input,
instant replay. If a terminal feature exists, iTerm2 probably has it.

**tmux `-CC` integration.** Unique to iTerm2. Control mode turns tmux windows
into native iTerm2 tabs and tmux panes into native splits. You get tmux session
persistence with macOS-native UI — no prefix keys, native scrollback, trackpad
resize. See the
[tmux lesson plan](../learn/tmux-lesson-plan.md#lesson-9-iterm2-integration) for
details.

**Semantic History.** `Cmd+Click` on file paths in terminal output opens them in
your editor. Understands `filename:line_number` to jump to the right line. Works
with relative paths, compiler errors, test failures — anything that prints a
file path. Ghostty's `Cmd+Click` handles URLs only.

**Scripting API.** Full Python and AppleScript automation. You can
programmatically create sessions, send keystrokes, change profiles, and query
terminal state.

**GUI configurability.** Every setting lives in a preferences pane. No config
file needed.

## Where Ghostty Wins

**Rendering performance.** GPU-accelerated text rendering produces smoother
scrolling and lower input latency, especially under heavy output (log tailing,
large builds).

**Memory efficiency.** ~40% less RAM under comparable workloads.

**Text rendering.** Better font shaping and ligature support out of the box.

**Cross-platform.** Same config file on macOS and Linux. One muscle memory
everywhere.

**Simplicity.** Sensible defaults mean less configuration to reach a good
experience. The config file is plain text — version-controllable, diffable,
shareable.

**Quick Terminal.** System-wide drop-down terminal toggled by a global hotkey.
Appears over any app, runs a command, disappears.

**Custom shaders.** GLSL shaders for visual effects (CRT scanlines, bloom, etc.)
that hot-reload on save.

## Where They're Comparable

- Tabs, splits, multiple windows
- 256-color and true color
- macOS native features (notifications, secure input, dark mode)
- Shell integration (prompt detection, directory tracking)
- Inline image display (iTerm2 protocol vs Kitty protocol)

## tmux `-CC`: The Feature That Locks You In

This deserves its own section because it's the single biggest factor in the
decision.

Normal tmux renders its own UI inside the terminal. iTerm2's `-CC` mode replaces
that UI entirely:

| Normal tmux                      | tmux -CC in iTerm2                            |
| -------------------------------- | --------------------------------------------- |
| tmux draws its own status bar    | No status bar — iTerm2 tabs instead           |
| `Ctrl-b %` to split              | `Cmd-D` to split                              |
| `Ctrl-b n` to switch windows     | `Cmd-Right` or click tabs                     |
| Mouse support requires config    | Native trackpad scrolling, clicking, resizing |
| Looks the same in every terminal | Looks like a normal iTerm2 window             |

**If you rely on `-CC` mode, switching to Ghostty means giving it up.** No other
terminal supports it.

**If you're learning tmux**, `-CC` hides what you're trying to learn. Standard
tmux works identically in both terminals.

## The Honest Trade-off

iTerm2 is the Swiss Army knife — it does everything, configured through menus.
Ghostty is the chef's knife — fewer features, but the ones it has are fast and
sharp.

Most developers who switch from iTerm2 to Ghostty report not missing what they
lost, because they weren't using most of iTerm2's features. The exceptions are
those who depend on `-CC` integration, broadcast input, or the scripting API.

## Decision Guide

| If you...                                    | Use                  |
| -------------------------------------------- | -------------------- |
| Rely on tmux `-CC` integration               | iTerm2               |
| Need broadcast input to multiple panes       | iTerm2               |
| Script your terminal with Python/AppleScript | iTerm2               |
| Value raw rendering performance              | Ghostty              |
| Work on both macOS and Linux                 | Ghostty              |
| Prefer config files over GUI preferences     | Ghostty              |
| Want a drop-down quick terminal              | Ghostty              |
| Don't use advanced iTerm2 features           | Either (try Ghostty) |

## See Also

- [Ghostty Lesson Plan](../learn/ghostty-lesson-plan.md) — 8-lesson progressive
  curriculum
- [tmux Lesson Plan](../learn/tmux-lesson-plan.md) — Includes iTerm2 `-CC`
  integration in Lesson 9
- [Ghostty Documentation](https://ghostty.org/docs)
- [iTerm2 Documentation](https://iterm2.com/documentation.html)
