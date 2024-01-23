local vim = vim
local api = vim.api
local util = require('vim.lsp.util')
local mason = require('mason')
local mason_lsp_config = require('mason-lspconfig')
local lspconfig = require('lspconfig')
local navic = require("nvim-navic")

local dap = require("dap")
local dapUI = require('dapui')
local dapGo = require("dap-go")
dapGo.setup()

dap.adapters.go = function(callback, config)
  local stdout = vim.loop.new_pipe(false)
  local handle
  local pid_or_err
  local port = 38697
  -- opts are passed to "executable" dap field
  local opts = {
    stdio = { nil, stdout },
    args = { "dap", "-l", "127.0.0.1:" .. port },
    detached = true,
  }
  handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
    stdout:close()
    handle:close()
    if code ~= 0 then
      print("dlv exited with code", code)
    end
  end)
  assert(handle, "Error running dlv: " .. tostring(pid_or_err))
  stdout:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then
      vim.schedule(function()
        require("dap.repl").append(chunk)
      end)
    end
  end)
  vim.defer_fn(function()
    callback({
      type = "server",
      host = "127.0.0.1",
      port = port,
      options = {
        initialize_timeout_sec = 60,
      },
    })
  end, 100)
end

-- env vars with defaults so lua doesn't complain
local tenantBucket = os.getenv("TENANT_BUCKET") or ""
local analyzerReportID = os.getenv("ANALYZER_REPORT_ID") or ""
local snapshotID = os.getenv("SNAPSHOT_ID") or ""

dap.configurations.go = {
  {
    name = "analyzer - report - from raw - s3",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/analyzer/",
    args = {
      "report", "analyze",
      "--app-url", os.getenv("SPEEDSCALE_APP_URL"),
      "--api-key", os.getenv("SPEEDSCALE_API_KEY"),
      "--report", "s3://" .. tenantBucket .. "/default/reports/" .. analyzerReportID .. ".json",
      "--artifact-src", "s3://" .. tenantBucket .. "/default",
      "--output-dir", ".",
    },
  },
  {
    name = "analyzer - report - from raw - local",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/analyzer/",
    args = {
      "report", "analyze",
      "--app-url", os.getenv("SPEEDSCALE_APP_URL"),
      "--api-key", os.getenv("SPEEDSCALE_API_KEY"),
      "--report", "/Users/josh/.speedscale/data/reports/" .. analyzerReportID .. ".json",
      "--output-dir", ".",
    },
  },
  {
    name = "analyzer - report - recreate",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/analyzer/",
    args = {
      "report", "analyze",
      "--app-url", os.getenv("SPEEDSCALE_APP_URL"),
      "--api-key", os.getenv("SPEEDSCALE_API_KEY"),
      "--report", "s3://" .. tenantBucket .. "/default/reports/" .. analyzerReportID .. ".json",
      "--output-dir", ".",
      "--recreate",
    },
  },
  {
    name = "analyzer - snapshot",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/analyzer/",
    args = {
      "snapshot",
      "--snapshot", "s3://" .. tenantBucket .. "/default/scenarios/" .. snapshotID .. ".json",
      "--output-dir", "./snapshot",
      -- "--raw", "s3select://" .. tenantBucket .. "/default/"
      "--app-url", "dev.speedscale.com",
      "--api-key", "$SPEEDSCALE_API_KEY",
      "--ignore-in-svc", "frontend:8080",
    }
  },
  {
    name = "analyzer - snapshot - local",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/analyzer/",
    args = {
      "snapshot",
      "--snapshot", "/Users/josh/.speedscale/data/snapshots/" .. snapshotID .. ".json",
      "--output-dir", "./snapshot",
      "--raw", "/Users/josh/.speedscale/data/snapshots/" .. snapshotID .. "/raw.jsonl"
    }
  },
  {
    name = "api-gateway",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/api-gateway/",
  },
  {
    name = "generator",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/generator/",
  },
  {
    name = "goproxy",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/goproxy/",
  },
  {
    name = "inspector",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/inspector/",
  },
  {
    name = "operator",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/operator/",
  },
  {
    name = "responder",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/responder/",
  },
  {
    name = "speedctl",
    type = "go",
    request = "launch",
    program = "/Users/josh/code/speedscale/speedctl/",
    args = {
      -- "replay", "3d03f3c8-f7f3-41be-8147-b367b5d96e50", "--test-config-id", "regression", "--mode", "generator-only", "--custom-url", "127.0.0.1:9000",
      "analyze", "filter", "delta_standard", "/Users/josh/code/speedscale/raw.jsonl",
      -- "infra", "replay", "--cluster", "jmt-dev", "-n", "beta-services", "notifications", "--snapshot-id", "e04bb776-89f0-42b7-afb7-9bb9a56bb3e1"
    }
  },
  {
    name = "current file",
    type = "go",
    request = "launch",
    program = "${file}",
  },
}

dapUI.setup(
  {
    force_buffers = true,
    layouts = { {
      elements = {
        { id = "breakpoints", size = 0.25 },
        { id = "stacks", size = 0.25 },
        { id = "watches", size = 0.25 },
        { id = "scopes", size = 0.25 },
      },
      position = "left",
      size = 40
    },
      {
        elements = { { id = "repl", size = 0.9 } },
        position = "bottom",
        size = 20
      },
    },
    render = {
      indent = 1,
      max_value_lines = 1000
    },
})



mason.setup({
  ui = {
    icons = {
      package_installed = '✓',
      package_pending = '➜',
      package_uninstalled = '✗',
    },
  },
})

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
  cmd = {"gopls", "serve"},
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
lspconfig.zk.setup({})
lspconfig.terraformls.setup({})
lspconfig.rust_analyzer.setup({
  on_attach = on_attach,
})


local fn = vim.fn

local M = {}
-- map helper
function M.map(mode, lhs, rhs, opts)
  local options = { noremap = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

M.map('n', '<leader>gD', ':vsp<CR><Cmd>lua vim.lsp.buf.definition()<CR>', opts)
M.map('n', '<leader>gS', ':sp<CR><Cmd>lua vim.lsp.buf.definition()<CR>', opts)
M.map('n', '<leader>gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
M.map('n', '<leader>gp', '<C-T>', opts)
M.map('n', '<leader>gA', '<Cmd>lua vim.lsp.buf.code_action()<CR>', opts)
M.map('n', '<leader>gi', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
M.map('n', '<leader>gu', ':Implementations<CR>', opts)
M.map('n', '<leader>gU', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
M.map('n', '<leader>gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
M.map('n', '<leader>gn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
M.map('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
M.map('n', '<leader>gR', ':References<CR>', opts)
M.map('n', '<leader>gt', '<Cmd>lua vim.lsp.buf.incoming_calls()<CR>', opts)
M.map('n', '<leader>fd', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
M.map('n', '<leader>a', ':DiagnosticsAll<CR>', opts)
M.map('n', '<leader>ra', ':CodeActions<CR>', opts)
M.map('n', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
M.map('i', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
M.map('n', '<leader>gO', '<Cmd>lua vim.lsp.buf.outgoing_calls()<CR>', opts)

M.map('n', '<leader>rl', '<cmd>lua vim.o.background="light"<CR>', opts)

-- WORKSPACE --
M.map('n', '<leader>Wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
M.map('n', '<leader>Wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
M.map('n', '<leader>Wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)

function DAPRun()
  -- vim.api.nvim_command('only')
  dap.continue()
  dapUI.open()
end
M.map('n', '<leader>dd', '<cmd>lua DAPRun()<CR>', opts)
function DAPTerminate()
  dap.terminate()
  dapUI.close()
end
M.map('n', '<leader>dq', '<cmd>lua DAPTerminate()<CR>', opts)
M.map('n', '<leader>d<space>', '<cmd>lua require("dap").continue()<CR>', opts)
M.map('n', '<leader>db', '<cmd>lua require("dap").toggle_breakpoint()<CR>', opts)
M.map('n', '<leader>dn', '<cmd>lua require("dap").step_over()<CR>', opts)
M.map('n', '<leader>di', '<cmd>lua require("dap").step_in()<CR>', opts)
M.map('n', '<leader>do', '<cmd>lua require("dap").step_out()<CR>', opts)
M.map('n', '<leader>dr', '<cmd>lua require("dap").restart()<CR>', opts)
M.map('n', '<leader>dh', '<cmd>lua require("dap").run_to_cursor()<CR>', opts)
M.map('n', '<leader>dI', '<cmd>lua require("dap.ui.widgets").hover()<CR>', opts)
M.map('n', '<leader>di', '<cmd>lua require("dap").step_into()<CR>', opts)
M.map('n', '<leader>du', '<cmd>lua require("dap").up()<CR>', opts)
M.map('n', '<leader>dU', '<cmd>lua require("dap").down()<CR>', opts)

function DebugTest()
  dapGo.debug_test()
  dapUI.open()
end
M.map('n', '<leader>dt', '<cmd>lua DebugTest()<CR>', opts)
function DebugLastTest()
  dapGo.debug_last_test()
  dapUI.open()
end
M.map('n', '<leader>dT', '<cmd>lua DebugLastTest()<CR>', opts)


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

local fzf_lsp = require('fzf_lsp')

---- LSPCONFIG ----
-- autojump to single reference
vim.lsp.handlers["textDocument/references"] = function(_, result, ctx, config)
  if not result or vim.tbl_isempty(result) then
    vim.notify("No references found")
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    config = config or {}
    local title = "References"
    local items = util.locations_to_items(result, client.offset_encoding)

    if #items == 2 then
      vim.notify("autojump to single reference")
      if items[1].lnum == vim.api.nvim_win_get_cursor(0)[1] then
        vim.cmd("e " .. items[2].filename .. "|" .. items[2].lnum)
      else
        vim.cmd("e " .. items[1].filename .. "|" .. items[1].lnum)
      end
    else
      if config.loclist then
        vim.fn.setloclist(0, {}, " ", { title = title, items = items, context = ctx })
        api.nvim_command("lopen")
      elseif config.on_list then
        assert(type(config.on_list) == "function", "on_list is not a function")
        config.on_list({ title = title, items = items, context = ctx })
      else
        vim.fn.setqflist({}, " ", { title = title, items = items, context = ctx })
        api.nvim_command("botright copen")
      end
    end
  end
end

