return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ensure_installed = {
				},
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					-- LSP servers
					"bashls",
					"docker_compose_language_service",
					"dockerls",
					"gitlab_ci_ls",
					"gopls",
					"jdtls",
					"jedi_language_server",
					"jqls",
					"lua_ls",
					"pylsp",
					"rust_analyzer",
					"terraformls",
					"tflint",
					"zls",
				},
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"SmiteshP/nvim-navic",
			"williamboman/mason.nvim",
		},
	},
	{ "hrsh7th/nvim-cmp", },
	{ "hrsh7th/cmp-nvim-lsp", },
	{ "hrsh7th/cmp-buffer", },
	{ "hrsh7th/cmp-path", },
	{
		"hrsh7th/cmp-nvim-lua",
		lazy = true,
		ft = { "lua" },
	},
	{ "mfussenegger/nvim-jdtls" },
	{
		"SmiteshP/nvim-navic",
		opts = {
			icons = {
				File          = "",
				Module        = "",
				Namespace     = "",
				Package       = "",
				Class         = "",
				Method        = "",
				Property      = "",
				Field         = "",
				Constructor   = "",
				Enum          = "",
				Interface     = "",
				Function      = "",
				Variable      = "",
				Constant      = "",
				String        = "",
				Number        = "",
				Boolean       = "",
				Array         = "",
				Object        = "",
				Key           = "",
				Null          = "",
				EnumMember    = "",
				Struct        = "",
				Event         = "",
				Operator      = "",
				TypeParameter = "",
			},
			separator = " > ",
		},
	},
}
