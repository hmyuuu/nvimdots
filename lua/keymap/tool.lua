local vim_path = require("core.global").vim_path
local bind = require("keymap.bind")
local map_cr = bind.map_cr
local map_cu = bind.map_cu
local map_cmd = bind.map_cmd
local map_callback = bind.map_callback
require("keymap.helpers")

local mappings = {
	plugins = {
		-- Plugin: vim-fugitive
		["n|gps"] = map_cr("G push"):with_noremap():with_silent():with_desc("git: Push"),
		["n|gpl"] = map_cr("G pull"):with_noremap():with_silent():with_desc("git: Pull"),
		["n|<leader>gG"] = map_cu("Git"):with_noremap():with_silent():with_desc("git: Open git-fugitive"),

		-- Plugin: edgy
		["n|<C-n>"] = map_callback(function()
				require("edgy").toggle("left")
			end)
			:with_noremap()
			:with_silent()
			:with_desc("filetree: Toggle"),

		-- Plugin: nvim-tree
		["n|<leader>nf"] = map_cr("NvimTreeFindFile"):with_noremap():with_silent():with_desc("filetree: Find file"),
		["n|<leader>nr"] = map_cr("NvimTreeRefresh"):with_noremap():with_silent():with_desc("filetree: Refresh"),

		-- Plugin: sniprun
		["v|<leader>r"] = map_cr("SnipRun"):with_noremap():with_silent():with_desc("tool: Run code by range"),
		["n|<leader>r"] = map_cu([[%SnipRun]]):with_noremap():with_silent():with_desc("tool: Run code by file"),

		-- Plugin: iron.nvim
		["n|<space>dt"] = map_callback(function()
				_debug_ts_node()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Show treesitter node types"),
		["n|<space>rr"] = map_cr("IronRepl"):with_noremap():with_silent():with_desc("repl: Toggle"),
		["n|<space>rR"] = map_cr("IronRestart"):with_noremap():with_silent():with_desc("repl: Restart"),
		["n|<space>rf"] = map_cr("IronFocus"):with_noremap():with_silent():with_desc("repl: Focus"),
		["n|<space>rh"] = map_cr("IronHide"):with_noremap():with_silent():with_desc("repl: Hide"),
		["n|<space>sc"] = map_callback(function()
				require("iron.core").send_motion()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send motion"),
		["v|<space>sc"] = map_callback(function()
				require("iron.core").visual_send()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send visual"),
		["n|<space>sl"] = map_callback(function()
				require("iron.core").send_line()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send line"),
		["n|<space>sf"] = map_callback(function()
				require("iron.core").send_file()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send file"),
		["n|<space>sp"] = map_callback(function()
				require("iron.core").send_paragraph()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send paragraph"),
		["n|<space>sb"] = map_callback(function()
				require("iron.core").send_code_block()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send code block"),
		["n|<space>sn"] = map_callback(function()
				require("iron.core").send_code_block_and_move()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send code block and move"),
		["n|<space>sa"] = map_callback(function()
				-- Smart send: try to find the appropriate code structure
				local ts_utils = require("nvim-treesitter.ts_utils")
				local node = ts_utils.get_node_at_cursor()

				-- Try to find the parent function, struct, or other code block
				local found = false
				while node do
					local node_type = node:type()
					-- Julia treesitter node types (updated for actual tree-sitter-julia grammar)
					if
						vim.tbl_contains({
							"function_definition",
							"short_function_definition",
							"struct_definition",
							"macro_definition",
							"let_statement",
							"for_statement",
							"while_statement",
							"if_statement",
							"try_statement",
							"quote_statement",
							"begin_statement",
							"do_clause",
						}, node_type)
					then
						-- Select the node and send it
						ts_utils.update_selection(0, node)
						vim.defer_fn(function()
							require("iron.core").visual_send()
						end, 10)
						found = true
						break
					end
					node = node:parent()
				end

				-- Fallback to sending paragraph if no structure found
				if not found then
					require("iron.core").send_paragraph()
				end
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Smart send (auto-detect structure)"),
		["n|<space><cr>"] = map_callback(function()
				-- Smart send and move: auto-detect structure, send, then jump to next structure
				local ts_utils = require("nvim-treesitter.ts_utils")
				local node = ts_utils.get_node_at_cursor()

				local target_types = {
					"function_definition",
					"short_function_definition",
					"struct_definition",
					"macro_definition",
					"let_statement",
					"for_statement",
					"while_statement",
					"if_statement",
					"try_statement",
					"quote_statement",
					"begin_statement",
					"do_clause",
				}

				-- Find the OUTERMOST matching structure (not the first one we encounter)
				local outermost_node = nil
				local current_node = node
				while current_node do
					local node_type = current_node:type()
					if vim.tbl_contains(target_types, node_type) then
						outermost_node = current_node
					end
					current_node = current_node:parent()
				end

				-- If we found an outermost structure, send it and move to next
				if outermost_node then
					-- Get the end position before selecting
					local _, _, end_row, _ = outermost_node:range()

					-- Select the node and send it
					ts_utils.update_selection(0, outermost_node)
					vim.defer_fn(function()
						require("iron.core").visual_send()
						-- Jump to next structure
						-- Start searching from the line after current structure
						local search_line = end_row + 2
						local total_lines = vim.api.nvim_buf_line_count(0)

						-- Find next structure
						local next_found = false
						for line = search_line, total_lines do
							vim.api.nvim_win_set_cursor(0, { line, 0 })
							local next_node = ts_utils.get_node_at_cursor()

							-- Again, find the outermost structure at this position
							local next_outermost = nil
							while next_node do
								if vim.tbl_contains(target_types, next_node:type()) then
									next_outermost = next_node
								end
								next_node = next_node:parent()
							end

							if next_outermost then
								local start_r, _, _, _ = next_outermost:range()
								vim.api.nvim_win_set_cursor(0, { start_r + 1, 0 })
								next_found = true
								break
							end
						end

						-- If no next structure found, go to end of buffer
						if not next_found then
							vim.api.nvim_win_set_cursor(0, { total_lines, 0 })
						end
					end, 10)
				else
					-- Fallback to sending paragraph and moving if no structure found
					require("iron.core").send_paragraph()
					vim.cmd("normal }")
				end
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Smart send and move to next"),
		["n|<space>saf"] = map_callback(function()
				vim.cmd("normal vaf")
				vim.defer_fn(function()
					require("iron.core").visual_send()
				end, 10)
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send function (outer)"),
		["n|<space>sif"] = map_callback(function()
				vim.cmd("normal vif")
				vim.defer_fn(function()
					require("iron.core").visual_send()
				end, 10)
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send function (inner)"),
		["n|<space>sac"] = map_callback(function()
				vim.cmd("normal vac")
				vim.defer_fn(function()
					require("iron.core").visual_send()
				end, 10)
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send class/struct (outer)"),
		["n|<space>s<cr>"] = map_callback(function()
				require("iron.core").send_cr()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Send CR"),
		["n|<space>s<space>"] = map_callback(function()
				require("iron.core").send_interrupt()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Interrupt"),
		["n|<space>sq"] = map_callback(function()
				require("iron.core").close_repl()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Exit"),
		["n|<space>cl"] = map_callback(function()
				require("iron.core").send_clear()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("repl: Clear"),

		-- Plugin: toggleterm
		["t|<Esc><Esc>"] = map_cmd([[<C-\><C-n>]]):with_noremap():with_silent(), -- switch to normal mode in terminal.
		["n|<C-\\>"] = map_cr("ToggleTerm direction=horizontal")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle horizontal"),
		["i|<C-\\>"] = map_cmd("<Esc><Cmd>ToggleTerm direction=horizontal<CR>")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle horizontal"),
		["t|<C-\\>"] = map_cmd("<Cmd>ToggleTerm<CR>")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle horizontal"),
		["n|<A-\\>"] = map_cr("ToggleTerm direction=vertical")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle vertical"),
		["i|<A-\\>"] = map_cmd("<Esc><Cmd>ToggleTerm direction=vertical<CR>")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle vertical"),
		["t|<A-\\>"] = map_cmd("<Cmd>ToggleTerm<CR>")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle vertical"),
		["n|<F5>"] = map_cr("ToggleTerm direction=vertical")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle vertical"),
		["i|<F5>"] = map_cmd("<Esc><Cmd>ToggleTerm direction=vertical<CR>")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle vertical"),
		["t|<F5>"] = map_cmd("<Cmd>ToggleTerm<CR>"):with_noremap():with_silent():with_desc("terminal: Toggle vertical"),
		["n|<A-d>"] = map_cr("ToggleTerm direction=float")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle float"),
		["i|<A-d>"] = map_cmd("<Esc><Cmd>ToggleTerm direction=float<CR>")
			:with_noremap()
			:with_silent()
			:with_desc("terminal: Toggle float"),
		["t|<A-d>"] = map_cmd("<Cmd>ToggleTerm<CR>"):with_noremap():with_silent():with_desc("terminal: Toggle float"),
		["n|<leader>gg"] = map_callback(function()
				_toggle_lazygit()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("git: Toggle lazygit"),

		-- Plugin: trouble
		["n|gt"] = map_cr("Trouble diagnostics toggle")
			:with_noremap()
			:with_silent()
			:with_desc("lsp: Toggle trouble list"),
		["n|<leader>lw"] = map_cr("Trouble diagnostics toggle")
			:with_noremap()
			:with_silent()
			:with_desc("lsp: Show workspace diagnostics"),
		["n|<leader>lp"] = map_cr("Trouble project_diagnostics toggle")
			:with_noremap()
			:with_silent()
			:with_desc("lsp: Show project diagnostics"),
		["n|<leader>ld"] = map_cr("Trouble diagnostics toggle filter.buf=0")
			:with_noremap()
			:with_silent()
			:with_desc("lsp: Show document diagnostics"),

		-- Plugin: telescope
		["n|<C-p>"] = map_callback(function()
				local search_backend = require("core.settings").search_backend
				if search_backend == "fzf" then
					local prompt_position = require("telescope.config").values.layout_config.horizontal.prompt_position
					require("fzf-lua").keymaps({
						fzf_opts = { ["--layout"] = prompt_position == "top" and "reverse" or "default" },
					})
				else
					_command_panel()
				end
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Toggle command panel"),
		["n|<leader>fc"] = map_callback(function()
				_telescope_collections(require("telescope.themes").get_dropdown())
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Open Telescope collections"),
		["n|<leader>ff"] = map_callback(function()
				require("search").open({ collection = "file" })
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Find files"),
		["n|<leader>fp"] = map_callback(function()
				require("search").open({ collection = "pattern" })
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Find patterns"),
		["v|<leader>fs"] = map_callback(function()
				local search_backend = require("core.settings").search_backend
				if search_backend == "fzf" then
					local default_opts = "--column --line-number --no-heading --color=always --smart-case"
					local opts = vim.fn.getcwd() == vim_path
							and default_opts .. " --no-ignore --hidden --glob '!.git/*'"
						or ""
					local text = require("fzf-lua.utils").get_visual_selection()
					require("fzf-lua").grep_project({
						search = text,
						rg_opts = opts,
					})
				else
					local opts = vim.fn.getcwd() == vim_path and { additional_args = { "--no-ignore" } } or {}
					require("telescope-live-grep-args.shortcuts").grep_visual_selection(opts)
				end
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Find word under cursor"),
		["n|<leader>fg"] = map_callback(function()
				require("search").open({ collection = "git" })
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Locate Git objects"),
		["n|<leader>fd"] = map_callback(function()
				require("search").open({ collection = "dossier" })
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Retrieve dossiers"),
		["n|<leader>fm"] = map_callback(function()
				require("search").open({ collection = "misc" })
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Miscellaneous"),
		["n|<leader>fr"] = map_cr("Telescope resume")
			:with_noremap()
			:with_silent()
			:with_desc("tool: Resume last search"),
		["n|<leader>fR"] = map_callback(function()
				local search_backend = require("core.settings").search_backend
				if search_backend == "fzf" then
					require("fzf-lua").resume()
				end
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Resume last search"),

		-- Plugin: dap
		["n|<F6>"] = map_callback(function()
				require("dap").continue()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Run/Continue"),
		["n|<F7>"] = map_callback(function()
				require("dap").terminate()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Stop"),
		["n|<F8>"] = map_callback(function()
				require("dap").toggle_breakpoint()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Toggle breakpoint"),
		["n|<F9>"] = map_callback(function()
				require("dap").step_into()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Step into"),
		["n|<F10>"] = map_callback(function()
				require("dap").step_out()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Step out"),
		["n|<F11>"] = map_callback(function()
				require("dap").step_over()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Step over"),
		["n|<leader>db"] = map_callback(function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Set breakpoint with condition"),
		["n|<leader>dc"] = map_callback(function()
				require("dap").run_to_cursor()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Run to cursor"),
		["n|<leader>dl"] = map_callback(function()
				require("dap").run_last()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Run last"),
		["n|<leader>do"] = map_callback(function()
				require("dap").repl.open()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("debug: Open REPL"),

		--- Plugin: CodeCompanion and edgy
		["n|<leader>cs"] = map_callback(function()
				_select_chat_model()
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Select Chat Model"),
		["nv|<leader>cc"] = map_callback(function()
				require("edgy").toggle("right")
			end)
			:with_noremap()
			:with_silent()
			:with_desc("tool: Toggle CodeCompanion"),
		["nv|<leader>ck"] = map_cr("CodeCompanionActions")
			:with_noremap()
			:with_silent()
			:with_desc("tool: CodeCompanion Actions"),
		["v|<leader>ca"] = map_cr("CodeCompanionChat Add")
			:with_noremap()
			:with_silent()
			:with_desc("tool: Add selection to CodeCompanion Chat"),

		-- Plugin: claudecode
		["n|<leader>ac"] = map_cr("ClaudeCode"):with_noremap():with_silent():with_desc("tool: Toggle Claude"),
		["n|<leader>af"] = map_cr("ClaudeCodeFocus"):with_noremap():with_silent():with_desc("tool: Focus Claude"),
		["n|<leader>ar"] = map_cr("ClaudeCode --resume"):with_noremap():with_silent():with_desc("tool: Resume Claude"),
		["n|<leader>aC"] = map_cr("ClaudeCode --continue")
			:with_noremap()
			:with_silent()
			:with_desc("tool: Continue Claude"),
		["n|<leader>am"] = map_cr("ClaudeCodeSelectModel")
			:with_noremap()
			:with_silent()
			:with_desc("tool: Select Claude model"),
		["n|<leader>ab"] = map_cr("ClaudeCodeAdd %"):with_noremap():with_silent():with_desc("tool: Add current buffer"),
		["v|<leader>as"] = map_cr("ClaudeCodeSend"):with_noremap():with_silent():with_desc("tool: Send to Claude"),
		["n|<leader>aa"] = map_cr("ClaudeCodeDiffAccept"):with_noremap():with_silent():with_desc("tool: Accept diff"),
		["n|<leader>ad"] = map_cr("ClaudeCodeDiffDeny"):with_noremap():with_silent():with_desc("tool: Deny diff"),
	},
}

bind.nvim_load_mapping(mappings.plugins)
