local vim = vim

-- disable virtual text for diagnostics
vim.diagnostic.config({
	virtual_text = false,
})

local navic = require("nvim-navic")
local default_capabilities = require("cmp_nvim_lsp").default_capabilities()

local on_attach = function(client, bufnr)
	if client.server_capabilities.documentSymbolProvider then
		navic.attach(client, bufnr)
	end
end

vim.lsp.config("lua_ls", {
	on_attach = function(client, bufnr)
		navic.attach(client, bufnr)
	end,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				-- make the LSP server aware of Neovim runtime files so we get LSP details on `vim.*`
				library = vim.api.nvim_get_runtime_file("", true),
			},
		},
	},
})
vim.lsp.enable("lua_ls")

vim.lsp.config("gopls", {
	capabilities = default_capabilities,
	on_attach = on_attach,
	cmd = {
		"gopls",
		"serve",
		-- "-logfile", "/tmp/gopls.log",
		-- "-rpc.trace",
		-- "--debug=localhost:6060",
	},
	settings = {
		gopls = {
			staticcheck = true,
			analyses = {
				unusedparams = true,
				unusedvariable = true,
				-- fieldalignment = true,
				nilness = true,
				unusedwrite = true,
				-- ref: https://staticcheck.dev/docs/checks/
				SA1000 = true, -- Invalid regular expression
				SA1002 = true, -- Invalid format in time.Parse
				SA1011 = true, -- Various methods in the strings package expect valid UTF-8, but invalid input is provided
				SA1013 = true,
				SA1014 = true,
				SA1019 = true,
				SA1020 = true,
				SA1023 = true,
				SA1025 = true,
				SA1028 = true,
				SA2000 = true,
				SA2002 = true,
				SA2003 = true,
				SA3000 = true,
				SA4001 = true,
				SA4004 = true,
				SA4005 = true,
				SA4006 = true, -- A value assigned to a variable is never read before being overwritten. Forgotten error check or dead code?
				SA4008 = true,
				SA4009 = true,
				SA4010 = true,
				SA4011 = true,
				SA4012 = true,
				SA4013 = true,
				SA4014 = true,
				SA4020 = true,
				SA4022 = true,
				SA4023 = true,
				SA4024 = true,
				SA4027 = true,
				SA5000 = true,
				SA5001 = true,
				SA5003 = true,
				SA5004 = true,
				SA5005 = true,
				SA5007 = true,
				SA5008 = true,
				SA5009 = true,
				SA5010 = true,
				SA5011 = true,
				SA5012 = true,
				SA6000 = true,
				SA6001 = true,
				SA6002 = true,
				SA6005 = true,
				SA9001 = true,
				SA9002 = true,
				SA9005 = true,
				SA9006 = true,
				S1017 = true,
				ST1008 = true,
				ST1017 = true,
			},
		},
	},
})
vim.lsp.enable("gopls")

vim.lsp.config("bashls", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("bashls")

vim.lsp.config("jedi_language_server", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("jedi_language_server")

vim.lsp.config("jdtls", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("jdtls")

vim.lsp.config("rust_analyzer", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("rust_analyzer")

vim.lsp.config("solargraph", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("solargraph")

vim.lsp.config("sqlls", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("sqlls")

vim.lsp.config("tflint", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("tflint")

vim.lsp.config("ts_ls", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("ts_ls")

vim.lsp.config("zk", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("zk")

vim.lsp.config("terraformls", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("terraformls")

vim.lsp.config("gitlab_ci_ls", {
	capabilities = default_capabilities,
	on_attach = on_attach,
})
vim.lsp.enable("gitlab_ci_ls")

vim.lsp.config("zls", {
	capabilities = default_capabilities,
	on_attach = on_attach,
	settings = {
		zls = {
			zig_exe_path = "/opt/homebrew/bin/zig",
		},
	},
})
vim.lsp.enable("zls")

-- supposed to be for proto but it doesn't work
-- local caps = require('cmp_nvim_lsp').default_capabilities()
-- caps.offsetEncoding = { 'utf-16' }
-- lspconfig.clangd.setup({
-- 	capabilities = caps,
-- 	root_dir = function(fname)
-- 		local cfgutil = require('lspconfig.util')
-- 		return cfgutil.root_pattern(
-- 			'Makefile',
-- 			'configure.ac',
-- 			'configure.in',
-- 			'config.h.in',
-- 			'meson.build',
-- 			'meson_options.txt',
-- 			'build.ninja'
-- 		)(fname) or cfgutil.root_pattern(
-- 			'compile_commands.json',
-- 			'compile_flags.txt'
-- 		)(fname) or cfgutil.find_git_anscestor(fname)
-- 	end,
-- 	cmd = {
-- 		'clangd',
-- 		'--background-index',
-- 		'--clang-tidy',
-- 		-- '--header-insertion-decorators',
-- 		-- '--header-insertion=iwyu',
-- 		-- '--import-insertions',
-- 		'--completion-style=detailed',
-- 		'--function-arg-placeholders',
-- 		'-j=4',
-- 	},
-- })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = ".gitlab*",
	callback = function()
		vim.bo.filetype = "yaml.gitlab"
	end,
})

local M = {}
-- map helper
function M.map(mode, lhs, rhs, opts)
	local options = { noremap = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- navigating code
M.map("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<CR>")
M.map("n", "<leader>gD", ":vsp<CR><Cmd>lua vim.lsp.buf.definition()<CR>")
M.map("n", "<leader>gS", ":sp<CR><Cmd>lua vim.lsp.buf.definition()<CR>")
M.map("n", "<leader>gi", "<cmd>lua vim.lsp.buf.hover()<CR>")
M.map("n", "<leader>gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
M.map("n", "<leader>gt", "<cmd>lua vim.lsp.buf.incoming_calls()<CR>")
M.map("n", "<leader>gO", "<Cmd>lua vim.lsp.buf.outgoing_calls()<CR>")
M.map("n", "<leader>gp", "<C-T>")
M.map("n", "<leader>gy", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
M.map("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>")
-- M.map("n", "<leader>gU", "<cmd>lua vim.lsp.buf.implementation()<CR>")

-- understanding
M.map("n", "<leader>ff", ":BuffergatorOpen<CR>")
M.map("n", "<leader>rj", "V:!jq<CR>")
M.map("v", "<leader>rj", ":!jq<CR>")

-- diagnosing
M.map("n", "<leader>fd", "<cmd>lua vim.diagnostic.open_float()<CR>")
M.map("n", "<C-S>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
M.map("i", "<C-S>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")

-- executing
M.map("n", "<leader>rr", ":wa<CR>:AsyncRun -mode=term -pos=thelp <Up><CR><Esc>")
M.map("n", "<leader>rt", ":AsyncRun -mode=term -pos=thelp ")
M.map("n", "<leader>rT", ":AsyncRun ")

---- NVIM-CMP ----
local cmp = require("cmp")

-- Register custom source for @ completion, which starts the path at nvim's working directory
cmp.register_source("cwd_path", require("cmp_sources.cwd_path").new())

cmp.setup({
	-- don"t guess at which option to select
	preselect = cmp.PreselectMode.None,
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
		end,
	},
	window = {
		-- completion = cmp.config.window.bordered(),
		-- documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		["<Tab>"] = cmp.mapping.select_next_item(),
		["<S-Tab>"] = cmp.mapping.select_prev_item(),
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{
			name = "ultisnips",
			priority = 0,
		},
		{
			name = "codeium",
			priority = 1,
		},
		{
			name = "nvim_lsp",
			priority = 1,
		},
		{
			name = "path",
			option = {
				path_mappings = {
					["@"] = "/tmp",
				},
				trailing_slash = true,
			},
			priority = 3,
		},
		-- {
		-- 	name = "cwd_path",
		-- 	priority = 3,
		-- },
	}, {
		{
			name = "nvim_lua",
			priority = 1,
		},
		{
			name = "buffer",
			priority = 4,
		},
	}),
})

cmp.setup.filetype("gitcommit", {
	sources = cmp.config.sources({
		{ name = "cmp_git" },
	}, {
		{ name = "buffer" },
	}),
})
