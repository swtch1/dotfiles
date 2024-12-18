return {
	"cuducos/yaml.nvim",
	lazy = true,
	ft = { "yaml", "yml" }, -- Load only for YAML files
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		-- Automatically show the YAML path in the winbar
		winbar = true,
	},
	config = function(_, opts)
		require("yaml_nvim").setup(opts)

		-- Set up an autocmd to update the winbar when the cursor moves
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			pattern = { "*.yaml", "*.yml" },
			callback = function()
				vim.opt_local.winbar = require("yaml_nvim").get_yaml_key()
			end,
		})
	end,
}
