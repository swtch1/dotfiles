return {
	{ -- file tree with direct modification
		"stevearc/oil.nvim",
		opts = {
			view_options = {
				show_hidden = true,
			},
		},
		dependencies = { { "echasnovski/mini.icons" } },
		-- not lazy so we can load directly into a directory
		lazy = false,
		cmd = { "Oil" },
		keys = {
			{ "<leader>fn", "<cmd>Oil<cr>", desc = "File Tree" },
		},
	},
}
