return {

	{
		'williamboman/mason.nvim',
		opts = {
			ui = {
				icons = {
					package_installed = '✓',
					package_pending = '➜',
					package_uninstalled = '✗',
				},
			},
		},
	},
	{
		'williamboman/mason-lspconfig.nvim',
		dependencies = {
			'williamboman/mason.nvim',
		},
		config = function()
			require("mason-lspconfig").setup()
		end,
	},
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
					local filetype = vim.bo.filetype
					if filetype == "typescript" or filetype == "typescriptreact" then
						return
					elseif filetype == "proto" then
						local view = vim.fn.winsaveview()
						vim.cmd([[silent! normal gg=G]]) -- ensure consistent spacing
						vim.cmd([[%s/\t/  /ge]])   -- replace tabs with two spaces
						vim.fn.winrestview(view)   -- restore the view so things don't jump around
					else
						vim.lsp.buf.format({ async = false })
					end
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
