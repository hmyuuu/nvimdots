return function()
	local iron = require("iron.core")
	local view = require("iron.view")

	iron.setup({
		config = {
			-- Whether a repl should be discarded or not
			scratch_repl = true,
			-- Your repl definitions come here
			repl_definition = {
				julia = {
					command = { "julia", "--banner=no" },
					block_dividers = { "# %%", "#%%", "##" },
					format = require("iron.fts.common").bracketed_paste,
				},
				python = {
					command = { "python3" },
					format = require("iron.fts.common").bracketed_paste_python,
					block_dividers = { "# %%", "#%%" },
				},
			},
			-- How the repl window will be displayed
			repl_open_cmd = view.split.vertical.botright(40),
		},
		-- If the highlight is on, you can change how it looks
		highlight = {
			italic = true,
		},
		ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
	})
end
