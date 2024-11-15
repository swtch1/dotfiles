return {
	"folke/trouble.nvim",
	opts = {
		focus = true,
		auto_close = true,
		modes = {
			diagnostics = {
				auto_jump = false,
				warn_no_results = true,
			},
			lsp_base = {
				auto_jump = true,
				warn_no_results = true,
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
		{ "<leader>gr", "<cmd>Trouble lsp_references open<cr>",           desc = "LSP references", },
		{ "<leader>fo", "<cmd>Trouble symbols focus<cr>",                 desc = "Outline", },
	},
}
