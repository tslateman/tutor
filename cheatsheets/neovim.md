# Neovim Commands (LazyVim)

## Search (Telescope + FZF)

| Keybinding   | Action                                   |
| ------------ | ---------------------------------------- |
| `<leader>sg` | Live grep - search text across all files |
| `<leader>sw` | Search word under cursor                 |
| `<leader>sf` | Find files by name                       |
| `<leader>/`  | Search in current buffer                 |
| `<leader>sR` | Resume last search                       |

## File Explorer (neo-tree)

| Keybinding   | Action               |
| ------------ | -------------------- |
| `<leader>e`  | Toggle file explorer |
| `<leader>fe` | Focus file explorer  |
| `q`          | Close (when focused) |

## Navigation

| Keybinding        | Action                  |
| ----------------- | ----------------------- |
| `<leader>bb`      | Switch buffers          |
| `<leader>bd`      | Delete buffer           |
| `<S-h>` / `<S-l>` | Previous/next buffer    |
| `<C-h/j/k/l>`     | Navigate between splits |
| `gd`              | Go to definition        |
| `gr`              | Go to references        |
| `K`               | Hover documentation     |
| `<C-o>` / `<C-i>` | Jump back/forward       |

## Code Actions

| Keybinding   | Action               |
| ------------ | -------------------- |
| `<leader>ca` | Code actions         |
| `<leader>cr` | Rename symbol        |
| `<leader>cf` | Format file          |
| `]d` / `[d`  | Next/prev diagnostic |
| `<leader>cd` | Line diagnostics     |

## Window Management

| Keybinding   | Action              |
| ------------ | ------------------- |
| `<leader>-`  | Split horizontal    |
| `<leader>\|` | Split vertical      |
| `<C-w>=`     | Equalize splits     |
| `<C-w>o`     | Close other windows |
| `<leader>wd` | Delete window       |

## Git

| Keybinding   | Action           |
| ------------ | ---------------- |
| `<leader>gg` | Open Lazygit     |
| `<leader>gf` | Git file history |
| `]h` / `[h`  | Next/prev hunk   |

## Useful Commands

| Command        | Action               |
| -------------- | -------------------- |
| `:Lazy`        | Plugin manager       |
| `:Mason`       | LSP/linter installer |
| `:LazyExtras`  | Enable extra plugins |
| `:checkhealth` | Diagnose issues      |

## Telescope Tips

Once in Telescope:

- `<C-n>` / `<C-p>` - navigate results
- `<CR>` - open file
- `<C-x>` - open in horizontal split
- `<C-v>` - open in vertical split
- `<C-q>` - send results to quickfix

## Discovery

Press `<leader>` and wait for which-key to show all available mappings.
