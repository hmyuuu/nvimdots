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
