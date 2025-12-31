# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Neovim configuration using lazy.nvim as the plugin manager. The configuration is split across multiple Lua modules:

- `init.vim` - Entry point that sources legacy vimrc and loads Lua config modules
- `lua/config/` - Core configuration (vim settings, LSP, lazy.nvim setup)
- `lua/plugins/` - Plugin-specific configurations (each file configures one or more related plugins)
- `lua/cmp_sources/` - Custom nvim-cmp completion sources

### Plugin Management

Plugins are managed by lazy.nvim and defined in `lua/plugins/*.lua` files. The plugin manager automatically imports all modules from the `plugins/` directory (see lua/config/lazy.lua:27).

### LSP Configuration

LSP servers are configured in `lua/config/lsp.lua` using Neovim's built-in LSP client. Servers include:
- gopls (Go) - with extensive staticcheck analyses enabled
- lua_ls (Lua)
- bashls, jedi_language_server, rust_analyzer, solargraph, ts_ls, etc.

Custom on_attach function integrates nvim-navic for breadcrumb navigation.

### Completion System

nvim-cmp is configured in `lua/config/lsp.lua:271-344` with multiple sources:
- ultisnips for snippets
- codeium for AI completion
- nvim_lsp for LSP completions
- path for file path completion
- buffer for buffer text completion

Custom cmp source in `lua/cmp_sources/cwd_path.lua` provides @ completion starting from nvim's working directory.

### Debugging (DAP)

DAP configuration in `lua/plugins/dap.lua` sets up debugging for Go programs with delve. Includes numerous pre-configured launch configurations for specific tools (analyzer, speedctl, proxymock, etc.) with environment variables pulled from shell environment.

Key functions:
- `DAPRun()` - Start debugging session
- `DapRunLast()` - Re-run last debug config (preserves prompt args)
- `DebugTest()` / `DebugLastTest()` - Debug Go tests

### Key Mappings Structure

Leader key is space. Mappings are organized by prefix:
- `<leader>r*` - "run" actions (execute, update, extract)
- `<leader>m*` - mode toggles (wrap, relative numbers, visual mode, etc.)
- `<leader>b*` - buffer operations (delete, move, copy path)
- `<leader>e*` - edit/split working directory
- `<leader>g*` - LSP navigation (definition, references, type, etc.)
- `<leader>f*` - finding/searching (Telescope, diagnostics)
- `<leader>d*` - debugging (DAP operations)
- `<leader>h/j/k/l` - window navigation
- `<leader>H/L` - jump to leftmost/rightmost window

### Auto-formatting

conform.nvim handles auto-formatting on save (lua/plugins/format.lua) with these formatters:
- Go: goimports
- JavaScript/TypeScript: prettier
- Lua: stylua
- Python: black (with line-length 9999 to disable wrapping)
- Zig: zigfmt

### Custom Features

**Decorated Yank** (`<c-y>` in visual mode): Yanks selection with line numbers and filename decoration.

**Buffer Reference Copy** (`<leader>rb` / `<leader>rB`): Copies buffer path with @ prefix and optional line numbers/ranges to clipboard.

**Comment Registers**: Macros `@f` and `@b` insert FIXME or BOOKMARK comments appropriate to the current filetype. The FIXME comment includes "(JMT)" which triggers a pre-commit hook to prevent accidental commits of debug code.

**Auto-reload**: Buffers automatically reload on focus gain (lua/config/vim.lua:84-89).

## Common Development Tasks

### Testing
Run tests using the async run mappings in lua/config/lsp.lua:267-269:
- `<leader>rr` - Prompt for command in terminal window
- `<leader>rt` - Async run with terminal
- `<leader>rT` - Async run without terminal

### Formatting
Files auto-format on save. To see formatter info: `:ConformInfo`

### LSP Operations
- `<leader>gd` - Go to definition
- `<leader>gD` - Go to definition in vertical split
- `<leader>gi` - Show hover info
- `<leader>gn` - Rename symbol
- `<leader>gr` - Show references
- `<leader>gy` - Go to type definition
- `<leader>gt` - Show incoming calls
- `<leader>gO` - Show outgoing calls

### Finding/Searching
- `<leader>p` - Find files (Telescope)
- `<leader>P` - Find files in current buffer's directory
- `<leader>fa` - Live grep (excludes fakeout directory)
- `<leader>fB` - Live grep in current buffer

### Debugging Go Programs
1. Set breakpoints with `<leader>db`
2. Start debugging with `<leader>dd` (select config) or `<leader>dD` (run last)
3. Step through with `<leader>dn` (next), `<leader>di` (step in), `<leader>do` (step out)
4. Stop with `<leader>dq`
5. Debug test at cursor: `<leader>dt`

## Plugin Update
Run `:Lazy update` or use `<leader>rl` mapping.
