return {
	{
		"jose-elias-alvarez/null-ls.nvim",
		event = "BufReadPre",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local null_ls = require("null-ls")
			local formatting = null_ls.builtins.formatting

			null_ls.setup({
				sources = {
					-- Formatting
					formatting.prettier.with({
						filetypes = {
							"javascript",
							"javascriptreact",
							"typescript",
							"typescriptreact",
							"json",
							"css",
							"scss",
							"less",
							"html",
							"yaml",
							"markdown",
						},
						prefer_local = "node_modules/.bin",
						extra_args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					}),
				},
			})
		end,
	},
}
