return {
	"folke/trouble.nvim",
	opts = {
		focus = true,
		auto_close = false,
		auto_fold = true,
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
					size = 0.3,
				},
			},
			lsp = {
				win = {
					size = 0.3,
				},
			},
		},
	},
	cmd = "Trouble",
	keys = {
		{ "<leader>ga", "<cmd>Trouble diagnostics open filter.buf=0<cr>", desc = "buffer diagnostics" },
		{ "<leader>gA", "<cmd>Trouble diagnostics open<cr>", desc = "all diagnostics" },
		{ "<leader>fo", "<cmd>Trouble symbols focus<cr>", desc = "outline" },
		{ "<leader>gl", "<cmd>Trouble lsp<cr>", desc = "LSP" },
		{ "<leader>gu", "<cmd>Trouble lsp_implementations<cr>", desc = "implementations" },
	},
}
