local vim = vim

-- disable virtual text for diagnostics
vim.diagnostic.config({
	virtual_text = false,
})

-- lsp.set_log_level("debug")

local lspconfig = require("lspconfig")
local navic = require("nvim-navic")

-- for some reason this messup go staticcheck
-- local mason_lsp_config = require("mason-lspconfig")
-- mason_lsp_config.setup()
-- mason_lsp_config.setup_handlers({
-- 	function(server_name)
-- 		lspconfig[server_name].setup({})
-- 	end,
-- })

local on_attach = function(client, bufnr)
	if client.server_capabilities.documentSymbolProvider then
		navic.attach(client, bufnr)
	end
end
lspconfig.lua_ls.setup({
	on_attach = function(client, bufnr)
		navic.attach(client, bufnr)
	end,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
})
lspconfig.gopls.setup({
	on_attach = on_attach,
	cmd = {
		"gopls", "serve",
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
lspconfig.bashls.setup({
	on_attach = on_attach,
})
lspconfig.clangd.setup({
	on_attach = on_attach,
})
lspconfig.jedi_language_server.setup({
	on_attach = on_attach,
})
lspconfig.jdtls.setup({
	on_attach = on_attach,
})
lspconfig.rust_analyzer.setup({
	on_attach = on_attach,
})
lspconfig.solargraph.setup({
	on_attach = on_attach,
})
lspconfig.sqlls.setup({})
lspconfig.tflint.setup({
	on_attach = on_attach,
})
lspconfig.tsserver.setup({
	on_attach = on_attach,
})
lspconfig.zk.setup({
	on_attach = on_attach,
})
lspconfig.terraformls.setup({
	on_attach = on_attach,
})
lspconfig.gitlab_ci_ls.setup({
	on_attach = on_attach,
})
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
M.map("n", "<leader>gy", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
M.map("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>")
M.map("n", "<leader>gU", "<cmd>lua vim.lsp.buf.implementation()<CR>")
M.map("n", "<leader>gp", "<C-T>")
M.map("n", "<leader>gi", "<cmd>lua vim.lsp.buf.hover()<CR>")
M.map("n", "<leader>gn", "<cmd>lua vim.lsp.buf.rename()<CR>")
M.map("n", "<leader>gt", "<cmd>lua vim.lsp.buf.incoming_calls()<CR>")
M.map("n", "<leader>gO", "<Cmd>lua vim.lsp.buf.outgoing_calls()<CR>")

-- understanding
M.map("n", "<leader>ff", ":BuffergatorOpen<CR>")
M.map("n", "<leader>rj", "V:!jq<CR>")
M.map("v", "<leader>rj", ":!jq<CR>")

-- diagnosing
M.map("n", "<leader>fd", "<cmd>lua vim.diagnostic.open_float()<CR>")
M.map("n", "<C-S>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
M.map("i", "<C-S>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")

-- executing
M.map("n", "<leader>rr", ":wa<CR>:AsyncRun<Up><CR><Esc>")
M.map("n", "<leader>rt", ":AsyncRun -mode=term -pos=thelp ")
M.map("n", "<leader>rT", ":AsyncRun -mode=term source ~/.zshrc-lite && ")

-- buffers
M.map("n", "<leader>h", "<C-W>h")
M.map("n", "<leader>j", "<C-W>j")
M.map("n", "<leader>k", "<C-W>k")
M.map("n", "<leader>l", "<C-W>l")
M.map("n", "<leader><Esc>", "<C-W><C-P>")
M.map("n", "<up>", ":resize -2<CR>")
M.map("n", "<down>", ":resize +2<CR>")
M.map("n", "<left>", ":vertical resize -2<CR>")
M.map("n", "<right>", ":vertical resize +2<CR>")
M.map("n", "<leader>ew", ":e %:p:h")
M.map("n", "<leader>es", ":sp %:p:h<CR>")
M.map("n", "<leader>ev", ":vsp %:p:h<CR>")
M.map("n", "<leader>bm", ":WinShift<CR>")
M.map("n", "<BS>", ":e#<CR>")
M.map("n", "<leader>bd", ":bd<CR>")
M.map("n", "<leader>bD", ":bd!<CR>")

-- -- debugging
-- function DAPRun()
--   -- vim.api.nvim_command("only")
--   dap.continue()
--   dapUI.open()
-- end
-- M.map("n", "<leader>dd", "<cmd>lua DAPRun()<CR>")
-- function DAPTerminate()
--   dap.terminate()
--   dapUI.close()
-- end
-- function DebugTest()
--   dapGo.debug_test()
--   dapUI.open()
-- end
-- M.map("n", "<leader>dt", "<cmd>lua DebugTest()<CR>")
-- function DebugLastTest()
--   dapGo.debug_last_test()
--   dapUI.open()
-- end
-- M.map("n", "<leader>dq", "<cmd>lua DAPTerminate()<CR>")
-- M.map("n", "<leader>d<space>", "<cmd>lua require("dap").continue()<CR>")
-- -- M.map("n", "<leader>db", "<cmd>lua require("dap").toggle_breakpoint()<CR>")
-- M.map("n", "<leader>dn", "<cmd>lua require("dap").step_over()<CR>")
-- M.map("n", "<leader>di", "<cmd>lua require("dap").step_in()<CR>")
-- M.map("n", "<leader>do", "<cmd>lua require("dap").step_out()<CR>")
-- M.map("n", "<leader>dr", "<cmd>lua require("dap").restart()<CR>")
-- M.map("n", "<leader>dh", "<cmd>lua require("dap").run_to_cursor()<CR>")
-- M.map("n", "<leader>dI", "<cmd>lua require("dap.ui.widgets").hover()<CR>")
-- M.map("n", "<leader>di", "<cmd>lua require("dap").step_into()<CR>")
-- M.map("n", "<leader>du", "<cmd>lua require("dap").up()<CR>")
-- M.map("n", "<leader>dU", "<cmd>lua require("dap").down()<CR>")
-- M.map("n", "<leader>dT", "<cmd>lua DebugLastTest()<CR>")

-- misc
M.map("n", "<leader>rd", ":vsp /Users/josh/code/ss/.envrc.local<CR>")
M.map("n", "<leader>rl", "<cmd>lua vim.o.background='light'<CR>")

---- NVIM-CMP ----
local cmp = require("cmp")
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
		["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
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
				trailing_slash = true,
			},
			priority = 3,
		},
	}, {
		{
			name = "nvim_lua",
			priority = 1,
		},
		{
			name = "buffer",
			priority = 4,
		},
	})
})

-- Set configuration for specific filetype.
cmp.setup.filetype("gitcommit", {
	sources = cmp.config.sources({
		{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
	}, {
		{ name = "buffer" },
	})
})
