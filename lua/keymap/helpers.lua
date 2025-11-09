_G._command_panel = function()
	require("telescope.builtin").keymaps({
		lhs_filter = function(lhs)
			return not string.find(lhs, "Þ")
		end,
	})
end

_G._flash_esc_or_noh = function()
	local flash_active, state = pcall(function()
		return require("flash.plugins.char").state
	end)
	if flash_active and state then
		state:hide()
	else
		pcall(vim.cmd.noh)
	end
end

_G._telescope_collections = function(picker_type)
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values
	local finder = require("telescope.finders")
	local pickers = require("telescope.pickers")
	picker_type = picker_type or {}

	local collections = vim.tbl_keys(require("search.tabs").collections)
	pickers
		.new(picker_type, {
			prompt_title = "Telescope Collections",
			finder = finder.new_table({ results = collections }),
			sorter = conf.generic_sorter(picker_type),
			attach_mappings = function(bufnr)
				actions.select_default:replace(function()
					actions.close(bufnr)
					local selection = action_state.get_selected_entry()
					require("search").open({ collection = selection[1] })
				end)

				return true
			end,
		})
		:find()
end

_G._toggle_inlayhint = function()
	local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
	vim.lsp.inlay_hint.enable(not is_enabled)
	vim.notify(
		(is_enabled and "Inlay hint disabled successfully" or "Inlay hint enabled successfully"),
		vim.log.levels.INFO,
		{ title = "LSP Inlay Hint" }
	)
end

_G._toggle_virtualtext = function()
	local _vl_enabled = require("core.settings").diagnostics_virtual_lines
	if _vl_enabled then
		local vl_config = not vim.diagnostic.config().virtual_lines
		vim.diagnostic.config({ virtual_lines = vl_config })
		vim.notify(
			(vl_config and "Virtual lines is now displayed" or "Virtual lines is now hidden"),
			vim.log.levels.INFO,
			{ title = "LSP Diagnostic" }
		)
	end
end

local _lazygit = nil
_G._toggle_lazygit = function()
	if vim.fn.executable("lazygit") == 1 then
		if not _lazygit then
			_lazygit = require("toggleterm.terminal").Terminal:new({
				cmd = "lazygit",
				direction = "float",
				close_on_exit = true,
				hidden = true,
			})
		end
		_lazygit:toggle()
	else
		vim.notify("Command [lazygit] not found!", vim.log.levels.ERROR, { title = "toggleterm.nvim" })
	end
end

local _repl_terminals = {}
_G._toggle_repl = function()
	-- Detect which REPL to use based on filetype
	local filetype = vim.bo.filetype
	local repl_cmd = nil
	local repl_name = nil

	if filetype == "julia" then
		if vim.fn.executable("julia") == 1 then
			repl_cmd = "julia"
			repl_name = "Julia REPL"
		end
	elseif filetype == "python" then
		if vim.fn.executable("ipython") == 1 then
			repl_cmd = "ipython"
			repl_name = "IPython"
		elseif vim.fn.executable("python") == 1 then
			repl_cmd = "python"
			repl_name = "Python REPL"
		end
	elseif filetype == "lua" then
		repl_cmd = "lua"
		repl_name = "Lua REPL"
	elseif filetype == "r" then
		if vim.fn.executable("R") == 1 then
			repl_cmd = "R"
			repl_name = "R Console"
		end
	else
		-- Default to bash/shell
		repl_cmd = vim.o.shell
		repl_name = "Shell"
	end

	if repl_cmd then
		-- Store the source buffer to configure slime later
		local source_buf = vim.api.nvim_get_current_buf()

		-- Create a REPL terminal for this filetype if it doesn't exist
		if not _repl_terminals[filetype] then
			_repl_terminals[filetype] = require("toggleterm.terminal").Terminal:new({
				cmd = repl_cmd,
				direction = "vertical",
				close_on_exit = true,
				hidden = true,
				on_open = function(term)
					-- Configure vim-slime to use this terminal
					vim.schedule(function()
						-- Set slime config for the source buffer with the terminal's channel ID
						local ok, chan_id = pcall(vim.api.nvim_buf_get_var, term.bufnr, "terminal_job_id")
						if ok and chan_id then
							vim.api.nvim_buf_set_var(source_buf, "slime_config", { jobid = chan_id })
							vim.notify(
								string.format("Opened %s (jobid: %s)", repl_name, chan_id),
								vim.log.levels.INFO,
								{ title = "REPL" }
							)
						else
							vim.notify("Failed to get terminal job ID", vim.log.levels.WARN, { title = "REPL" })
						end
					end)
				end,
			})
		end

		-- Toggle and ensure config is set if opening
		local term = _repl_terminals[filetype]
		local was_open = term:is_open()
		term:toggle()

		-- If terminal is now open and wasn't before, set config
		if not was_open and term:is_open() then
			vim.schedule(function()
				local ok, chan_id = pcall(vim.api.nvim_buf_get_var, term.bufnr, "terminal_job_id")
				if ok and chan_id then
					vim.api.nvim_buf_set_var(source_buf, "slime_config", { jobid = chan_id })
				end
			end)
		end
	else
		vim.notify("No REPL found for filetype: " .. filetype, vim.log.levels.ERROR, { title = "REPL" })
	end
end

_G._select_chat_model = function()
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local finder = require("telescope.finders")
	local pickers = require("telescope.pickers")
	local type = require("telescope.themes").get_dropdown()
	local conf = require("telescope.config").values
	local models = require("core.settings").chat_models
	local current_model = models[1]

	pickers
		.new(type, {
			prompt_title = "(CodeCompanion) Select Model",
			finder = finder.new_table({ results = models }),
			sorter = conf.generic_sorter(type),
			attach_mappings = function(bufnr)
				actions.select_default:replace(function()
					actions.close(bufnr)
					current_model = action_state.get_selected_entry()[1]
					vim.g.current_chat_model = current_model
					vim.notify("Model selected: " .. current_model, vim.log.levels.INFO, { title = "CodeCompanion" })
				end)

				return true
			end,
		})
		:find()
end

-- Debug helper to inspect treesitter node types
_G._debug_ts_node = function()
	local ts_utils = require("nvim-treesitter.ts_utils")
	local node = ts_utils.get_node_at_cursor()

	if not node then
		vim.notify("No treesitter node at cursor", vim.log.levels.WARN, { title = "Treesitter Debug" })
		return
	end

	local node_types = {}
	local current = node
	while current do
		table.insert(node_types, current:type())
		current = current:parent()
	end

	local msg = "Node types (innermost to outermost):\n" .. table.concat(node_types, "\n → ")
	vim.notify(msg, vim.log.levels.INFO, { title = "Treesitter Debug" })
	print(msg)
end

-- Helper for iron.nvim: smart send code structures to REPL
_G._iron_smart_send = function(opts)
	opts = opts or {}
	local move_to_next = opts.move_to_next or false

	local ts_utils = require("nvim-treesitter.ts_utils")

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

	-- Helper function to find outermost matching structure from a node
	local function find_outermost(start_node)
		local outermost = nil
		local current = start_node
		while current do
			if vim.tbl_contains(target_types, current:type()) then
				outermost = current
			end
			current = current:parent()
		end
		return outermost
	end

	local node = ts_utils.get_node_at_cursor()
	local outermost_node = find_outermost(node)

	if outermost_node then
		local _, _, end_row, _ = outermost_node:range()
		ts_utils.update_selection(0, outermost_node)

		vim.defer_fn(function()
			require("iron.core").visual_send()

			if move_to_next then
				-- Jump to next structure
				local search_line = end_row + 2
				local total_lines = vim.api.nvim_buf_line_count(0)
				local next_found = false

				for line = search_line, total_lines do
					vim.api.nvim_win_set_cursor(0, { line, 0 })
					local next_node = ts_utils.get_node_at_cursor()
					local next_outermost = find_outermost(next_node)

					if next_outermost then
						local start_r, _, _, _ = next_outermost:range()
						vim.api.nvim_win_set_cursor(0, { start_r + 1, 0 })
						next_found = true
						break
					end
				end

				if not next_found then
					vim.api.nvim_win_set_cursor(0, { total_lines, 0 })
				end
			end
		end, 10)
	else
		-- Fallback to sending paragraph
		require("iron.core").send_paragraph()
		if move_to_next then
			vim.cmd("normal }")
		end
	end
end
