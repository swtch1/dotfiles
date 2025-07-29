return {
	--  {'nvim-treesitter/nvim-treesitter', opts={'do': ':TSUpdate'}},
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "lua", "vim", "vimdoc", "query", "go" },
				auto_install = true,

				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
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
	{ "nvim-treesitter/playground" },
}
