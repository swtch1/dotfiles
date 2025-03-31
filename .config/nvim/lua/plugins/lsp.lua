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
			vim.api.nvim_create_augroup("lsp_format", { clear = true })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("lsp_format", { clear = true }),
				callback = function(event)
					local clients = vim.lsp.get_active_clients({ bufnr = event.buf })
					if #clients > 0 then
						local client = clients[1]
						if client.supports_method("textDocument/formatting") then
							local filetype = vim.bo[event.buf].filetype
							if filetype == "go" then
								-- go formatting handled in lsp.lua
								return
								-- stuff to skip
							elseif filetype == "<placeholder>" then
								return
							else
								-- add any missing imports
								if client.supports_method("textDocument/codeAction") then
									vim.lsp.buf.code_action({
										context = { only = { "source.organizeImports" } },
										apply = true,
									})
								end
								-- format the buffer
								vim.lsp.buf.format({
									async = false,
									timeout_ms = 5000,
									bufnr = event.buf, -- explicitly specify the buffer
								})
							end
						end
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
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				javascript = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				typescript = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				javascriptreact = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				typescriptreact = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				json = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				css = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				scss = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				less = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				html = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				yaml = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				markdown = {
					prettier = {
						args = {
							"--tab-width=2",
							"--use-tabs=false",
						},
					},
				},
				-- This conform stuff was built by AI because I didn't
				-- want to read the docs and it doesn't work correctly.
				-- It can work, because the direct buf command works - it just doesn't right now
				proto = {
					buf = {
						command = "buf",
						args = { "format", "-w" },
						stdin = true,
						debug = true,
						require_cwd = true,
						env = {
							BUF_FORMAT_STYLE = "google"
						},
					},
				},
			},
			format_after_save = {
				timeout_ms = 500,
				quiet = false,
			},
		},
		config = function(_, opts)
			require("conform").setup(opts)
		end,
	},
}
