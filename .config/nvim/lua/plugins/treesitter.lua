return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			-- ensure parsers are installed (async, no-op if already present)
			require("nvim-treesitter").install({
				"lua", "vim", "vimdoc", "query", "go",
				"markdown", "markdown_inline",
				"bash", "python", "javascript", "typescript", "json", "yaml",
			})

			-- enable treesitter highlighting for all filetypes
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})

			-- manual highlighting configuration
			do
				local function clear_property_highlight()
					vim.api.nvim_set_hl(0, "@property", {})
					vim.api.nvim_set_hl(0, "@variable.parameter", {})
					vim.api.nvim_set_hl(0, "@variable.member", {})
				end
				clear_property_highlight()

				-- And ensure it's reapplied if the colorscheme changes
				local augroup = vim.api.nvim_create_augroup("TreeSitterCustomPropertyHighlight", { clear = true })
				vim.api.nvim_create_autocmd("ColorScheme", {
					group = augroup,
					pattern = "*",
					callback = clear_property_highlight,
					desc = "Clear @property highlight after colorscheme load",
				})
			end
		end,
	},
}
