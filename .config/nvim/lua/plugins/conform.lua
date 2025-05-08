return {
	"stevearc/conform.nvim",
	-- ensure loaded before save
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = {
		notify_on_error = true,
		format_on_save = {
			timeout_ms = 10000,
			lsp_fallback = false,
		},
		formatters_by_ft = {
			go = { "goimports" },
			javascript = { "prettier" },
			lua = { "stylua" },
			python = { "black" },
			typescript = { "prettier" },
			zig = { "zigfmt" },
		},
	},
	-- formatter specific config
	formatters = {
		-- run `<formatter> --help` for options
		black = {
			-- don't wrap long lines
			args = { "--line-length", "9999" },
		},
		prettier = {
			-- args don't seem to work for this but a .prettier.json file does so just do that
		},
	},
}
