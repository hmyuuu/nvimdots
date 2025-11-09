# Julia REPL and DAP Setup Summary

## Overview
Set up Julia development environment in Neovim with REPL interaction (iron.nvim) and debugging support (nvim-dap-julia).

## Components Configured

### 1. Julia DAP (Debug Adapter Protocol)
**Files Modified:**
- `/Users/hmyuuu/.config/nvim/lua/modules/plugins/tool.lua` (lines 167-173)
- `/Users/hmyuuu/.config/nvim/lua/modules/configs/tool/dap/clients/julia.lua` (new file)
- `/Users/hmyuuu/.config/nvim/lua/modules/configs/tool/dap/init.lua` (lines 86-100)

**Features:**
- Julia debugger integration via `nvim-dap-julia` plugin
- Virtual text support showing variable values during debugging
- Auto-configured adapter using plugin defaults

**Keymaps:**
- `<F6>` - Run/Continue debugging
- `<F7>` - Stop debugging
- `<F8>` - Toggle breakpoint
- `<F9>` - Step into
- `<F10>` - Step out
- `<F11>` - Step over
- `<leader>db` - Set conditional breakpoint
- `<leader>dc` - Run to cursor
- `<leader>do` - Open REPL

### 2. Iron.nvim REPL
**Files Modified:**
- `/Users/hmyuuu/.config/nvim/lua/modules/plugins/tool.lua` (lines 47-51)
- `/Users/hmyuuu/.config/nvim/lua/modules/configs/tool/iron.lua` (new file)

**Configuration:**
- Julia REPL with `--banner=no` flag
- Bracketed paste format for multi-line code
- Block dividers: `# %%`, `#%%`, `##`
- Vertical split on right side (40 columns)
- Scratch REPL mode enabled

**Keymaps:**
- `<space>rr` - Toggle REPL
- `<space>rR` - Restart REPL
- `<space>rf` - Focus REPL
- `<space>rh` - Hide REPL
- `<space>sc` - Send motion
- `<space>sl` - Send line
- `<space>sf` - Send file
- `<space>sp` - Send paragraph
- `<space>sb` - Send code block
- `<space>sn` - Send code block and move
- `<space>saf` - Send function (outer)
- `<space>sif` - Send function (inner)
- `<space>sac` - Send class/struct (outer)
- `<space>s<cr>` - Send CR
- `<space>s<space>` - Send interrupt
- `<space>sq` - Exit REPL
- `<space>cl` - Clear REPL
- `<v|space>sc` - Send visual selection

### 3. Smart Send Features
**Files Modified:**
- `/Users/hmyuuu/.config/nvim/lua/keymap/tool.lua` (lines 79-210)
- `/Users/hmyuuu/.config/nvim/lua/keymap/helpers.lua` (lines 200-220)

**Smart Send Keymaps:**
- `<space><cr>` - Smart send: Auto-detect and send current structure (function, struct, loop, etc.)
- `<space>S` - Smart send and jump to next structure
- `<space>dt` - Debug: Show treesitter node types at cursor

**Detected Structures:**
- `function_definition` / `short_function_definition`
- `struct_definition`
- `macro_definition`
- `let_statement`
- `for_statement` / `while_statement`
- `if_statement` / `try_statement`
- `quote_statement` / `begin_statement`
- `do_clause`

**Fallback Behavior:**
- If no structure detected, sends paragraph (text block separated by empty lines)

### 4. Treesitter Support
**Files Modified:**
- `/Users/hmyuuu/.config/nvim/lua/core/settings.lua` (line 159)

**Added:**
- Julia treesitter parser to `treesitter_deps`

**Purpose:**
- Enables syntax tree parsing for smart structure detection
- Required for `<space><cr>` and `<space>S` keymaps to work

## Installation Steps

1. **Install Julia Treesitter Parser:**
   ```vim
   :TSInstall julia
   ```
   Or restart Neovim (auto-installs from `treesitter_deps`)

2. **Verify Installation:**
   - Open a Julia file
   - Press `<space>dt` to see treesitter node types
   - Should show node hierarchy (not "no nodes")

3. **Test REPL:**
   - Open Julia file
   - Press `<space>rr` to toggle REPL
   - Press `<space>sl` to send current line
   - Press `<space><cr>` to send current function

4. **Test DAP:**
   - Set breakpoint with `<F8>`
   - Start debugging with `<F6>`
   - DAP UI should open automatically

## Workflow Examples

### Interactive Development:
1. Write Julia function
2. Press `<space><cr>` to send function to REPL
3. Test in REPL interactively
4. Press `<space>S` to send current function and jump to next

### Sequential Execution:
1. Place cursor at first function
2. Press `<space>S` repeatedly
3. Each press sends current structure and jumps to next
4. Executes entire file function-by-function

### Debugging:
1. Set breakpoints with `<F8>`
2. Press `<F6>` to start debugging
3. Use `<F9>/<F10>/<F11>` to step through code
4. View variable values inline (virtual text)

## Troubleshooting

### Smart Send Always Falls Back to Paragraph:
- **Cause:** Julia treesitter parser not installed
- **Fix:** Run `:TSInstall julia` and restart Neovim

### REPL Position Wrong:
- **Expected:** Vertical split on right (40 columns)
- **Check:** `lua/modules/configs/tool/iron.lua` line 23
- **Setting:** `view.split.vertical.botright(40)`

### DAP Not Working:
- **Check:** `nvim-dap-julia` plugin installed
- **Verify:** `lua/modules/plugins/tool.lua` lines 169-173
- **Test:** Run `:lua require('dap-julia').setup()` manually

### Debug Keymap Shows "No Nodes":
- **Cause:** Treesitter parser missing or file not recognized as Julia
- **Check:** `:set filetype?` should show `filetype=julia`
- **Fix:** Install parser or set filetype manually

## Files Changed Summary

1. **Plugin Configuration:**
   - `lua/modules/plugins/tool.lua` - Added iron.nvim and nvim-dap-julia

2. **DAP Configuration:**
   - `lua/modules/configs/tool/dap/init.lua` - Added virtual text support
   - `lua/modules/configs/tool/dap/clients/julia.lua` - Julia DAP adapter (new)
   - `lua/modules/configs/tool/dap/clients/python.lua` - Fixed mason-registry error

3. **REPL Configuration:**
   - `lua/modules/configs/tool/iron.lua` - Iron.nvim setup for Julia (new)

4. **Keymaps:**
   - `lua/keymap/tool.lua` - Added all iron.nvim and smart send keymaps
   - `lua/keymap/helpers.lua` - Added treesitter debug helper

5. **Settings:**
   - `lua/core/settings.lua` - Added Julia to treesitter_deps

## Key Differences from vim-slime

| Feature | vim-slime | iron.nvim |
|---------|-----------|-----------|
| Send mechanism | Manual jobid config | Auto-managed |
| Code blocks | Manual `# %%` markers | Auto-detect structures |
| Multi-line | Basic | Bracketed paste |
| Smart send | No | Yes (treesitter-based) |
| Jump to next | No | Yes (`<space>S`) |

## Next Steps

1. **Learn Workflow:**
   - Practice using `<space><cr>` for quick function sends
   - Use `<space>S` for sequential execution
   - Experiment with different send commands

2. **Customize:**
   - Adjust REPL width in `iron.lua` (line 23)
   - Add more node types to smart send if needed
   - Modify keymaps to match your preferences

3. **Integrate:**
   - Combine with LSP for complete IDE experience
   - Use DAP for debugging complex issues
   - Leverage treesitter for code navigation

## References

- [iron.nvim docs](https://github.com/Vigemus/iron.nvim)
- [nvim-dap-julia docs](https://github.com/kdheepak/nvim-dap-julia)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [tree-sitter-julia](https://github.com/tree-sitter/tree-sitter-julia)
