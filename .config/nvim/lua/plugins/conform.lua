return {
	'stevearc/conform.nvim',
	-- ensure loaded before save
	event = { 'BufWritePre' },
	cmd = { 'ConformInfo' },
	opts = {
		notify_on_error = true,
		format_on_save = {
			timeout_ms = 2000,
			lsp_fallback = true,
		},
		formatters_by_ft = {
			lua = { 'stylua' },
			go = { 'goimports', 'gofmt' },
			zig = { 'zigfmt' },
			python = { 'black' },
		},
	},
	-- formatter specific config
	formatters = {
		-- run `black --help` for options
		black = {
			-- don't wrap long lines
			args = { '--line-length', '9999', },
		},
	},
}
