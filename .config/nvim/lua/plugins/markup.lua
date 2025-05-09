return {
	{ -- in-line markdown preview
		lazy = true,
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "Avante", "codecompanion" },
	},
	{ -- manual markdown preview
		"ellisonleao/glow.nvim",
		lazy = true,
		cmd = "Glow",
		opts = {
			height_ratio = 0.85,
		},
	},
	{ -- yaml path
		"cuducos/yaml.nvim",
		lazy = true,
		ft = { "yaml", "yml" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			winbar = true,
		},
		config = function(_, opts)
			require("yaml_nvim").setup(opts)
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				pattern = { "*.yaml", "*.yml" },
				callback = function()
					vim.opt_local.winbar = require("yaml_nvim").get_yaml_key()
				end,
			})
		end,
	},
	{ -- json path
		"phelipetls/jsonpath.nvim",
		ft = { "json" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			vim.opt_local.winbar = "%{%v:lua.require'jsonpath'.get()%}"
		end,
	},
}
