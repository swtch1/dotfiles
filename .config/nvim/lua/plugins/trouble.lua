return {
	"folke/trouble.nvim",
	opts = {}, -- for default options, refer to the configuration section for custom setup.
	cmd = "Trouble",
	keys = {
		{
			"<leader>A", "<cmd>Trouble diagnostics toggle<cr>", desc = "All Diagnostics",
		},
		{
			"<leader>a", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics",
		},
	},
}
