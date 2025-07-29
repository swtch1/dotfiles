return {
	{
		"folke/snacks.nvim",
		-- load early so vim.ui.select / vim.ui.input get overridden
		priority = 1000,
		lazy = false,
		opts = {
			-- handle large files more gracefully
			bigfile = { enabled = true },
			-- provide a startup dashboard for common actions
			-- dashboard = { enabled = true },
			explorer = { enabled = true },
			-- indent guides
			indent = {
				enabled = true,
				scope = {
					-- hilight the current scope
					enabled = false,
				},
			},
			-- better vim.ui.input
			input = { enabled = true },
			-- notifications in a floating window
			notifier = {
				enabled = true,
				timeout = 3000,
				width = { min = 50, max = 0.8 },
				height = { min = 1, max = 10 },
			},
			-- for selecting all sorts of things
			-- picker = { enabled = true },
			-- render files targeted on startup before loading plugins
			quickfile = { enabled = true },
			-- smooth scrolling
			-- scroll = { enabled = true },
			-- toggle keymaps - could be used to make debug keymaps easier
			toggle = { enabled = true },
		},
	},
}
