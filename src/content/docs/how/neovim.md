---
title: "Neovim Commands (LazyVim)"
description:
  LazyVim keybindings for Telescope, neo-tree, LSP, DAP debugging, buffers,
  splits, Git, and configuration patterns.
---

LazyVim on top of Neovim. All keybindings assume the default `<leader>` is
`<Space>`.

## Search (Telescope)

| Keybinding   | Action                        |
| ------------ | ----------------------------- |
| `<leader>sf` | Find files by name            |
| `<leader>sg` | Live grep across all files    |
| `<leader>sw` | Search word under cursor      |
| `<leader>/`  | Search in current buffer      |
| `<leader>sR` | Resume last search            |
| `<leader>s"` | Search registers              |
| `<leader>sa` | Search autocommands           |
| `<leader>sb` | Search open buffers           |
| `<leader>sc` | Search command history        |
| `<leader>sC` | Search commands               |
| `<leader>sd` | Search diagnostics (document) |
| `<leader>sD` | Search diagnostics (all)      |
| `<leader>sh` | Search help tags              |
| `<leader>sk` | Search keymaps                |
| `<leader>sm` | Search marks                  |
| `<leader>sM` | Search man pages              |
| `<leader>so` | Search options                |
| `<leader>ss` | Search document symbols       |
| `<leader>sS` | Search workspace symbols      |

### Inside Telescope

| Keybinding        | Action                       |
| ----------------- | ---------------------------- |
| `<C-n>` / `<C-p>` | Navigate results             |
| `<CR>`            | Open file                    |
| `<C-x>`           | Open in horizontal split     |
| `<C-v>`           | Open in vertical split       |
| `<C-t>`           | Open in new tab              |
| `<C-q>`           | Send all results to quickfix |
| `<M-q>`           | Send selected to quickfix    |
| `<C-u>` / `<C-d>` | Scroll preview up/down       |

## File Explorer (neo-tree)

| Keybinding   | Action               |
| ------------ | -------------------- |
| `<leader>e`  | Toggle file explorer |
| `<leader>fe` | Focus file explorer  |
| `<leader>fE` | Explorer at cwd      |

### Inside neo-tree

| Key | Action                               |
| --- | ------------------------------------ |
| `a` | Add file/directory (end `/` for dir) |
| `d` | Delete                               |
| `r` | Rename                               |
| `c` | Copy                                 |
| `m` | Move                                 |
| `y` | Copy path to clipboard               |
| `p` | Paste                                |
| `P` | Preview                              |
| `s` | Open in split                        |
| `S` | Open in vertical split               |
| `.` | Toggle hidden files                  |
| `q` | Close                                |

## Buffers and Tabs

| Keybinding           | Action                |
| -------------------- | --------------------- |
| `<leader>bb`         | Switch buffers        |
| `<leader>bd`         | Delete buffer         |
| `<leader>bD`         | Delete buffer (force) |
| `<leader>bo`         | Delete other buffers  |
| `<leader>bp`         | Toggle pin buffer     |
| `<S-h>`              | Previous buffer       |
| `<S-l>`              | Next buffer           |
| `<leader><tab>l`     | Last tab              |
| `<leader><tab>f`     | First tab             |
| `<leader><tab><tab>` | New tab               |
| `<leader><tab>d`     | Close tab             |
| `<leader><tab>]`     | Next tab              |
| `<leader><tab>[`     | Previous tab          |

## Navigation

### Motions

| Keybinding  | Action                     |
| ----------- | -------------------------- |
| `gd`        | Go to definition           |
| `gD`        | Go to declaration          |
| `gr`        | Go to references           |
| `gI`        | Go to implementation       |
| `gy`        | Go to type definition      |
| `K`         | Hover documentation        |
| `gK`        | Signature help             |
| `<C-o>`     | Jump back                  |
| `<C-i>`     | Jump forward               |
| `<C-]>`     | Follow tag/definition      |
| `%`         | Jump to matching bracket   |
| `]]` / `[[` | Next/prev class or section |
| `]f` / `[f` | Next/prev function start   |

### Flash (quick jump)

| Keybinding | Action                       |
| ---------- | ---------------------------- |
| `s`        | Flash jump (in normal mode)  |
| `S`        | Flash treesitter select      |
| `r`        | Remote flash (operator mode) |
| `<C-s>`    | Toggle flash search          |

## Window Management

| Keybinding       | Action                  |
| ---------------- | ----------------------- |
| `<C-h/j/k/l>`    | Navigate between splits |
| `<leader>-`      | Split horizontal        |
| `<leader>\|`     | Split vertical          |
| `<C-w>=`         | Equalize splits         |
| `<C-w>o`         | Close other windows     |
| `<leader>wd`     | Delete window           |
| `<leader>wm`     | Maximize toggle         |
| `<C-Up/Down>`    | Resize height           |
| `<C-Left/Right>` | Resize width            |

## LSP

| Keybinding   | Action               |
| ------------ | -------------------- |
| `<leader>ca` | Code actions         |
| `<leader>cA` | Source action        |
| `<leader>cr` | Rename symbol        |
| `<leader>cf` | Format file          |
| `<leader>cF` | Format range         |
| `<leader>cd` | Line diagnostics     |
| `<leader>cl` | LSP info             |
| `]d` / `[d`  | Next/prev diagnostic |
| `]e` / `[e`  | Next/prev error      |
| `]w` / `[w`  | Next/prev warning    |

### Diagnostics

```vim
" Toggle inline diagnostics
:lua vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })

" Show all diagnostics in location list
:lua vim.diagnostic.setloclist()

" Show all diagnostics in quickfix
:lua vim.diagnostic.setqflist()
```

## Debugging (DAP)

LazyVim's DAP integration requires the `lazyvim.plugins.extras.dap.core` extra.

| Keybinding   | Action                 |
| ------------ | ---------------------- |
| `<leader>db` | Toggle breakpoint      |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Continue / start       |
| `<leader>dC` | Run to cursor          |
| `<leader>ds` | Step over              |
| `<leader>di` | Step into              |
| `<leader>do` | Step out               |
| `<leader>dp` | Pause                  |
| `<leader>dr` | Toggle REPL            |
| `<leader>dl` | Run last               |
| `<leader>dt` | Terminate              |
| `<leader>du` | Toggle DAP UI          |
| `<leader>de` | Evaluate expression    |
| `<leader>dw` | Toggle watches         |

### Python DAP Setup

```lua
-- In lua/plugins/dap-python.lua
return {
  "mfussenegger/nvim-dap-python",
  ft = "python",
  dependencies = { "mfussenegger/nvim-dap" },
  config = function()
    require("dap-python").setup("python3")
  end,
}
```

## Testing (neotest)

Requires the `lazyvim.plugins.extras.test.core` extra.

| Keybinding   | Action           |
| ------------ | ---------------- |
| `<leader>tt` | Run nearest test |
| `<leader>tT` | Run file tests   |
| `<leader>tr` | Run last test    |
| `<leader>ts` | Toggle summary   |
| `<leader>to` | Toggle output    |
| `<leader>tS` | Stop tests       |

## Git

| Keybinding    | Action                |
| ------------- | --------------------- |
| `<leader>gg`  | Open Lazygit          |
| `<leader>gf`  | Git file history      |
| `<leader>gl`  | Git log               |
| `<leader>gL`  | Git log (cwd)         |
| `<leader>gb`  | Git blame line        |
| `<leader>gB`  | Git browse (open URL) |
| `]h` / `[h`   | Next/prev hunk        |
| `<leader>ghs` | Stage hunk            |
| `<leader>ghr` | Reset hunk            |
| `<leader>ghp` | Preview hunk          |
| `<leader>ghb` | Blame line (full)     |
| `<leader>ghd` | Diff this             |

## Commands

### Plugin Management

| Command        | Action                              |
| -------------- | ----------------------------------- |
| `:Lazy`        | Plugin manager (install/update/log) |
| `:Lazy sync`   | Update all plugins                  |
| `:Lazy clean`  | Remove unused plugins               |
| `:Lazy health` | Check plugin health                 |
| `:Mason`       | LSP/linter/formatter installer      |
| `:LazyExtras`  | Enable/disable extra plugins        |
| `:checkhealth` | Diagnose issues                     |

### Useful Ex Commands

```vim
" Open terminal
:terminal

" Diff two buffers side by side
:diffthis  " (in each buffer)
:diffoff   " (to stop)

" Replace in file
:%s/old/new/gc     " with confirmation
:%s/old/new/g      " without confirmation

" Replace in visual selection
:'<,'>s/old/new/g

" Execute shell command, insert output
:r !date
:r !curl -s https://httpbin.org/ip

" Sort lines (visual selection)
:'<,'>sort
:'<,'>sort u    " unique
:'<,'>sort n    " numeric

" Save as root
:w !sudo tee %
```

## Configuration

LazyVim uses four config files in `lua/config/`:

```text
~/.config/nvim/lua/config/
├── autocmds.lua   # Autocommands
├── keymaps.lua    # Custom keybindings
├── lazy.lua       # lazy.nvim bootstrap (rarely edited)
└── options.lua    # Vim options
```

### Custom Keymaps

```lua
-- lua/config/keymaps.lua
local map = vim.keymap.set

-- Quick save
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })

-- Move lines up/down in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Center after jumps
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search (centered)" })

-- Filetype-specific keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    map("n", "<leader>pt", "<cmd>lua require('neotest').run.run()<cr>",
      { buffer = true, desc = "Run test" })
    map("n", "<leader>pb", "<cmd>lua require('dap').toggle_breakpoint()<cr>",
      { buffer = true, desc = "Toggle breakpoint" })
  end,
})
```

### Custom Options

```lua
-- lua/config/options.lua
local opt = vim.opt

opt.scrolloff = 8          -- Lines above/below cursor
opt.relativenumber = true  -- Relative line numbers (LazyVim default)
opt.wrap = false           -- No line wrap
opt.tabstop = 4            -- Tab width
opt.shiftwidth = 4         -- Indent width
opt.expandtab = true       -- Spaces not tabs
opt.clipboard = "unnamedplus"  -- System clipboard (LazyVim default)
```

### Adding Plugins

```lua
-- lua/plugins/example.lua
-- Each file in lua/plugins/ returns a table of plugin specs
return {
  -- Override existing plugin config
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "python", "typescript", "lua", "rust", "go" },
    },
  },

  -- Add a new plugin
  {
    "github/copilot.vim",
    event = "InsertEnter",
  },

  -- Disable a LazyVim default plugin
  { "folke/flash.nvim", enabled = false },
}
```

### Language Extras

Enable via `:LazyExtras` or `lazyvim.json`:

```json
{
  "extras": [
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.lang.typescript",
    "lazyvim.plugins.extras.lang.rust",
    "lazyvim.plugins.extras.lang.go",
    "lazyvim.plugins.extras.dap.core",
    "lazyvim.plugins.extras.test.core"
  ]
}
```

Each language extra installs the appropriate LSP server, formatter, linter, and
treesitter grammar. `:Mason` shows what each extra installed.

## Discovery

Press `<leader>` and wait — which-key shows all available mappings grouped by
prefix. Drill down by pressing the group key:

| Prefix          | Group                |
| --------------- | -------------------- |
| `<leader>b`     | Buffers              |
| `<leader>c`     | Code                 |
| `<leader>d`     | Debug                |
| `<leader>f`     | File/find            |
| `<leader>g`     | Git                  |
| `<leader>gh`    | Git hunks            |
| `<leader>s`     | Search               |
| `<leader>t`     | Test                 |
| `<leader>u`     | UI toggles           |
| `<leader>w`     | Windows              |
| `<leader>x`     | Diagnostics/quickfix |
| `<leader><tab>` | Tabs                 |

## See Also

- [tmux](tmux.md) — Sessions, windows, panes, copy mode
- [Terminal Emulators](terminal-emulators.md) — iTerm2 vs Ghostty, rendering
- [Debugging](debugging.md) — Debuggers and profilers beyond the editor
- [Git](git.md) — Git commands complementing Lazygit
- [CLI-First](../why/cli-first.md) — Why terminal-first workflows
