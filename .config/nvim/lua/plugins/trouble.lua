return {
	"folke/trouble.nvim",
	opts = {
		focus = true,
		auto_close = false,
		modes = {
			diagnostics = {
				auto_jump = false,
				warn_no_results = true,
			},
			lsp_base = {
				auto_jump = true,
				warn_no_results = true,
				follow = false,
				params = {
					include_current = true,
				},
			},
			symbols = {
				win = {
					position = "left",
				},
			},
		},
	},
	cmd = "Trouble",
	keys = {
		{ "<leader>a",  "<cmd>Trouble diagnostics open<cr>",              desc = "All diagnostics", },
		{ "<leader>A",  "<cmd>Trouble diagnostics open filter.buf=0<cr>", desc = "Buffer diagnostics", },
		{ "<leader>gr", "<cmd>Trouble lsp<cr>",                           desc = "LSP", },
		{ "<leader>fo", "<cmd>Trouble symbols focus<cr>",                 desc = "Outline", },
	},
}
