local vim = vim

-- disable virtual text for diagnostics
vim.diagnostic.config({
  virtual_text = false,
})

-- lsp.set_log_level('debug')

local mason_lsp_config = require('mason-lspconfig')
local lspconfig = require('lspconfig')
local navic = require("nvim-navic")

mason_lsp_config.setup()

mason_lsp_config.setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({})
  end,
})

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
	globals = { 'vim' },
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
      analyses = {
        unusedparams = true,
        unusedvariable = true,
        -- fieldalignment = true,
        nilness = true,
        unusedwrite = true,
        SA1000,
        SA1002,
        SA1011,
        SA1013,
        SA1014,
        SA1019,
        SA1020,
        SA1023,
        SA1025,
        SA1028,
        SA2000,
        SA2002,
        SA2003,
        SA3000,
        SA4001,
        SA4004,
        SA4005,
        SA4006,
        SA4008,
        SA4009,
        SA4010,
        SA4011,
        SA4012,
        SA4013,
        SA4014,
        SA4020,
        SA4022,
        SA4023,
        SA4024,
        SA4027,
        SA5000,
        SA5001,
        SA5003,
        SA5004,
        SA5005,
        SA5007,
        SA5008,
        SA5009,
        SA5010,
        SA5011,
        SA5012,
        SA6000,
        SA6001,
        SA6002,
        SA6005,
        SA9001,
        SA9002,
        SA9005,
        SA9006,
        S1017,
        ST1008,
        ST1017,
      },
      staticcheck = true,
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
M.map('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
M.map('n', '<leader>gD', ':vsp<CR><Cmd>lua vim.lsp.buf.definition()<CR>')
M.map('n', '<leader>gS', ':sp<CR><Cmd>lua vim.lsp.buf.definition()<CR>')
M.map('n', '<leader>gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
M.map('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>')
M.map('n', '<leader>gU', '<cmd>lua vim.lsp.buf.implementation()<CR>')
M.map('n', '<leader>gp', '<C-T>')
M.map('n', '<leader>gi', '<cmd>lua vim.lsp.buf.hover()<CR>')
M.map('n', '<leader>gn', '<cmd>lua vim.lsp.buf.rename()<CR>')
M.map('n', '<leader>gt', '<cmd>lua vim.lsp.buf.incoming_calls()<CR>')
M.map('n', '<leader>gO', '<Cmd>lua vim.lsp.buf.outgoing_calls()<CR>')

-- understanding
M.map('n', '<leader>ff', ':BuffergatorOpen<CR>')
M.map('n', '<leader>rj', 'V:!jq<CR>')
M.map('v', '<leader>rj', ':!jq<CR>')

-- diagnosing
M.map('n', '<leader>fd', '<cmd>lua vim.diagnostic.open_float()<CR>')
M.map('n', '<leader>ra', ':CodeActions<CR>')
M.map('n', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
M.map('i', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')

-- executing
M.map('n', '<leader>rr', ':wa<CR>:AsyncRun<Up><CR><Esc>')
M.map('n', '<leader>rt', ':AsyncRun -mode=term -pos=thelp ')
M.map('n', '<leader>rT', ':AsyncRun -mode=term source ~/.zshrc-lite && ')

-- buffers
M.map('n', '<leader>h', '<C-W>h')
M.map('n', '<leader>j', '<C-W>j')
M.map('n', '<leader>k', '<C-W>k')
M.map('n', '<leader>l', '<C-W>l')
M.map('n', '<leader><Esc>', '<C-W><C-P>')
M.map('n', '<up>', ':resize -2<CR>')
M.map('n', '<down>', ':resize +2<CR>')
M.map('n', '<left>', ':vertical resize -2<CR>')
M.map('n', '<right>', ':vertical resize +2<CR>')
M.map('n', '<leader>ew', ':e %:p:h')
M.map('n', '<leader>es', ':sp %:p:h<CR>')
M.map('n', '<leader>ev', ':vsp %:p:h<CR>')
M.map('n', '<leader>bm', ':WinShift<CR>')
M.map('n', '<BS>', ':e#<CR>')
M.map('n', '<leader>bd', ':bd<CR>')
M.map('n', '<leader>bD', ':bd!<CR>')

-- -- debugging
-- function DAPRun()
--   -- vim.api.nvim_command('only')
--   dap.continue()
--   dapUI.open()
-- end
-- M.map('n', '<leader>dd', '<cmd>lua DAPRun()<CR>')
-- function DAPTerminate()
--   dap.terminate()
--   dapUI.close()
-- end
-- function DebugTest()
--   dapGo.debug_test()
--   dapUI.open()
-- end
-- M.map('n', '<leader>dt', '<cmd>lua DebugTest()<CR>')
-- function DebugLastTest()
--   dapGo.debug_last_test()
--   dapUI.open()
-- end
-- M.map('n', '<leader>dq', '<cmd>lua DAPTerminate()<CR>')
-- M.map('n', '<leader>d<space>', '<cmd>lua require("dap").continue()<CR>')
-- -- M.map('n', '<leader>db', '<cmd>lua require("dap").toggle_breakpoint()<CR>')
-- M.map('n', '<leader>dn', '<cmd>lua require("dap").step_over()<CR>')
-- M.map('n', '<leader>di', '<cmd>lua require("dap").step_in()<CR>')
-- M.map('n', '<leader>do', '<cmd>lua require("dap").step_out()<CR>')
-- M.map('n', '<leader>dr', '<cmd>lua require("dap").restart()<CR>')
-- M.map('n', '<leader>dh', '<cmd>lua require("dap").run_to_cursor()<CR>')
-- M.map('n', '<leader>dI', '<cmd>lua require("dap.ui.widgets").hover()<CR>')
-- M.map('n', '<leader>di', '<cmd>lua require("dap").step_into()<CR>')
-- M.map('n', '<leader>du', '<cmd>lua require("dap").up()<CR>')
-- M.map('n', '<leader>dU', '<cmd>lua require("dap").down()<CR>')
-- M.map('n', '<leader>dT', '<cmd>lua DebugLastTest()<CR>')

-- misc
M.map('n', '<leader>rd', ':vsp /Users/josh/code/ss/.envrc.local<CR>')
M.map('n', '<leader>rl', '<cmd>lua vim.o.background="light"<CR>')

---- NVIM-CMP ----
local cmp = require('cmp')
cmp.setup({
  -- don't guess at which option to select
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
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    {
      name = 'ultisnips',
      priority = 0,
    },
    {
      name = 'nvim_lsp',
      priority = 1,
    },
    {
      name = 'path',
      option = {
        trailing_slash = true,
      },
      priority = 3,
    },
  }, {
    {
      name = 'nvim_lua',
    },
    {
      name = 'buffer',
      priority = 4,
    },
  })
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
  }, {
    { name = 'buffer' },
  })
})

