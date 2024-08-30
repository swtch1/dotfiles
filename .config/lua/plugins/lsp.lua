return {
	-- for some reason this messup go staticcheck
	-- {
	-- 	'williamboman/mason.nvim',
	-- 	opts = {
	-- 		ui = {
	-- 			icons = {
	-- 				package_installed = '✓',
	-- 				package_pending = '➜',
	-- 				package_uninstalled = '✗',
	-- 			},
	-- 		},
	-- 	},
	-- },
	-- {
	-- 	'williamboman/mason-lspconfig.nvim',
	-- 	dependencies = {
	-- 		'williamboman/mason.nvim',
	-- 	},
	-- 	config = function()
	-- 		require("mason-lspconfig").setup()
	-- 	end,
	-- },
	{
		'neovim/nvim-lspconfig',
		dependencies = {
			'SmiteshP/nvim-navic',
			'williamboman/mason.nvim',
		},
		init = function()
			-- auto format on save
			vim.api.nvim_create_augroup("AutoFormat", {})
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = "AutoFormat",
				callback = function()
					vim.lsp.buf.format({ async = false })
				end,
			})
		end,
	},
	{ 'hrsh7th/nvim-cmp', },
	{ 'hrsh7th/cmp-nvim-lsp', },
	{ 'hrsh7th/cmp-buffer', },
	{ 'hrsh7th/cmp-path', },
	{
		'hrsh7th/cmp-nvim-lua',
		lazy = true,
		ft = { 'lua' },
	},
	{ 'mfussenegger/nvim-jdtls' },
	{
		'SmiteshP/nvim-navic',
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
			separator = ' > ',
		},
	},
}
