local vim = vim

-- disable virtual text for diagnostics
vim.diagnostic.config({
  virtual_text = false,
})


-- lsp.set_log_level('debug')

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
local appUrl = os.getenv("SPEEDSCALE_APP_URL") or ""
local apiKey = os.getenv("SPEEDSCALE_API_KEY") or ""
local tenantBucket = os.getenv("TENANT_BUCKET") or ""
local analyzerReportID = os.getenv("ANALYZER_REPORT_ID") or ""
local snapshotID = os.getenv("SNAPSHOT_ID") or ""
local config = os.getenv("CONFIG") or ""

dap.configurations.go = {
  {
    name = "analyzer - report - from raw - s3",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/analyzer/",
    args = {
      "report", "analyze",
      "--app-url", appUrl,
      "--api-key", apiKey,
      "--report", "s3://" .. tenantBucket .. "/default/reports/" .. analyzerReportID .. ".json",
      "--artifact-src", "s3://" .. tenantBucket .. "/default",
      "--output-dir", ".",
      "--reanalyze",
    },
  },
  {
    name = "analyzer - report - from raw - local reanalyze",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/analyzer/",
    args = {
      "report", "analyze",
      "--app-url", appUrl,
      "--api-key", apiKey,
      "--report", "/Users/josh/.speedscale/data/reports/" .. analyzerReportID .. ".json",
      "--artifact-src", "/Users/josh/.speedscale/data/reports/" .. analyzerReportID,
      "--output-dir", ".",
      "--reanalyze",
    },
  },
  {
    name = "analyzer - report - recreate",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/analyzer/",
    args = {
      "report", "analyze",
      "--app-url", appUrl,
      "--api-key", apiKey,
      "--report", "s3://" .. tenantBucket .. "/default/reports/" .. analyzerReportID .. ".json",
      "--output-dir", ".",
      "--recreate",
    },
  },
  {
    name = "analyzer - snapshot - s3select",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/analyzer/",
    args = {
      "snapshot",
      "--app-url", appUrl,
      "--api-key", apiKey,
      "--snapshot", "s3://" .. tenantBucket .. "/default/scenarios/" .. snapshotID .. ".json",
      "--raw", "s3select://" .. tenantBucket .. "/default/",
      "--output-dir", "./snapshot/",
      "--recreate",
    }
  },
  {
    name = "analyzer - snapshot - from raw file",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/analyzer/",
    args = {
      "snapshot",
      "--app-url", appUrl,
      "--api-key", apiKey,
      "--snapshot", "s3://" .. tenantBucket .. "/default/scenarios/" .. snapshotID .. ".json",
      "--raw", "s3://" .. tenantBucket .. "/default/scenarios/" .. snapshotID .. "/raw.json",
      -- "--raw", "s3select://" .. tenantBucket .. "/default/",
      "--output-dir", "./snapshot",
      "--recreate",
      -- "--ignore-in-svc", "frontend:8080",
    }
  },
  {
    name = "analyzer - snapshot - local",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/analyzer/",
    args = {
      "snapshot",
      "--app-url", appUrl,
      "--api-key", apiKey,
      "--snapshot", "/Users/josh/.speedscale/data/snapshots/" .. snapshotID .. ".json",
      "--raw", "/Users/josh/.speedscale/data/snapshots/" .. snapshotID .. "/raw.jsonl",
      "--output-dir", "./snapshot",
    }
  },
  {
    name = "api-gateway",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/api-gateway/",
  },
  {
    name = "generator",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/generator/",
  },
  {
    name = "goproxy",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/goproxy/",
  },
  {
    name = "inspector",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/inspector/",
  },
  {
    name = "operator",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/operator/",
  },
  {
    name = "responder",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/responder/",
  },
  {
    name = "sos",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/sos/",
    args = {
      "validate",
        "--tags", "collector=v2.1.344",
        "--tags", "forwarder=v2.1.344",
        "--tags", "generator=v2.1.344",
        "--tags", "goproxy=v2.1.344",
        "--tags", "inspector=v2.1.344",
        "--tags", "operator=v2.1.344",
        "--tags", "responder=v2.1.344",
        "--tags", "speedscale-cli=v2.1.344",
        "--speedctl=v2.1.344",
        "--kustomize", "../../kraken/master/k8s/v2/",
        "--tracking-tag=jmt-kraken",
        "--speedscale-home-path", "/Users/josh/.speedscale",
        "--cluster-name=jmt-dev",
        "--timeout=20m",
        "--operator=false",
        "--istio-install=false",
        "--istio-inject=false",
        "--env-teardown=false",
        "--deployment-name=notifications",
        "--invert=false",
        "--validate-dlp=false",
        "--validate-replays", "urlgoals=39010415-958c-42a7-88f1-852c6dc7d22e:kraken-notifications-latest-urlgoals",
        "--verbose",
        "--test-teardown=false", -- delete deployment after test
        "--snapshot-capture-for=60s",
    }
  },
  {
    name = "speedctl",
    type = "go",
    request = "launch",
    program = vim.fn.getcwd() .. "/speedctl/",
    args = {
      -- "--config", config, "replay", snapshotID, "--custom-url", "http://localhost:8080", "--test-config-id", "jmt-dev",
      "--config", config, "replay", snapshotID, "--test-config-id", "regression_no_mocks_1_assertion_endpoints",
      -- "--config", config, "create", "snapshot", "--name", "from-speedctl", "--service", "frontend", "--start", "15m", "--end", "20m",
    }
  },
  {
    name = "current file",
    type = "go",
    request = "launch",
    program = "${file}",
  },
}

-- -- Shaun's analyzer debugger with snapshot ID prompt
-- dap.configurations.go = {
--   setmetatable(
--     {
--       name = 'analyze local snapshot',
--       type = 'go',
--       request = 'launch',
--       program = vim.fn.getcwd() .. '/analyzer/',
--       args = {
--         'snapshot',
--         '--local',
--         '--rm',
--         '--recreate',
--       },
--     },
--     {
--       __call = function(cfg)
--         local snapshotID = vim.g.snapshot_id or vim.fn.input('Snapshot ID: ', '')
--         local extra = {
--           '--snapshot', os.getenv('HOME') .. '/.speedscale/data/snapshots/' .. snapshotID .. '.json',
--           '--output-dir', '/tmp/analyze-snapshot/' .. snapshotID,
--           '--raw', os.getenv('HOME') .. '/.speedscale/data/snapshots/' .. snapshotID .. '/raw.jsonl',
--         }

--         for k, v in pairs(extra) do cfg['args'][k+4] = v end

--         return cfg
--       end
--     }
--   ),
-- }


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
  cmd = {"gopls", "serve", "-logfile", "/tmp/gopls.log", "-rpc.trace", "--debug=localhost:6060"},
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

function DAPRun()
  -- vim.api.nvim_command('only')
  dap.continue()
  dapUI.open()
end
M.map('n', '<leader>dd', '<cmd>lua DAPRun()<CR>')
function DAPTerminate()
  dap.terminate()
  dapUI.close()
end
function DebugTest()
  dapGo.debug_test()
  dapUI.open()
end
M.map('n', '<leader>dt', '<cmd>lua DebugTest()<CR>')
function DebugLastTest()
  dapGo.debug_last_test()
  dapUI.open()
end

-- navigating code
M.map('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
M.map('n', '<leader>gD', ':vsp<CR><Cmd>lua vim.lsp.buf.definition()<CR>')
M.map('n', '<leader>gS', ':sp<CR><Cmd>lua vim.lsp.buf.definition()<CR>')
M.map('n', '<leader>gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
M.map('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>')
M.map('n', '<leader>gR', ':References<CR>')
M.map('n', '<leader>gu', ':Implementations<CR>')
M.map('n', '<leader>gU', '<cmd>lua vim.lsp.buf.implementation()<CR>')
M.map('n', '<leader>gp', '<C-T>')
M.map('n', '<leader>gi', '<cmd>lua vim.lsp.buf.hover()<CR>')
M.map('n', '<leader>gn', '<cmd>lua vim.lsp.buf.rename()<CR>')
M.map('n', '<leader>gt', '<cmd>lua vim.lsp.buf.incoming_calls()<CR>')
M.map('n', '<leader>gO', '<Cmd>lua vim.lsp.buf.outgoing_calls()<CR>')

-- navigating projects
M.map('n', '<leader>fn', ':NERDTreeFind<CR>')

-- understanding
M.map('n', '<leader>fo', ':Outline<CR>')
M.map('n', '<leader>ff', ':BuffergatorOpen<CR>')
M.map('n', '<leader>rj', 'V:!jq<CR>')
M.map('v', '<leader>rj', ':!jq<CR>')

-- diagnosing
M.map('n', '<leader>a', ':DiagnosticsAll<CR>')
M.map('n', '<leader>fd', '<cmd>lua vim.diagnostic.open_float()<CR>')
M.map('n', '<leader>ra', ':CodeActions<CR>')
M.map('n', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
M.map('i', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')

-- executing
M.map('n', '<leader>rr', ':wa<CR>:AsyncRun<Up><CR><Esc>')
M.map('n', '<leader>rt', ':AsyncRun -mode=term -pos=thelp ')
M.map('n', '<leader>rT', ':AsyncRun -mode=term source ~/.zshrc-lite && ')

-- debugging
M.map('n', '<leader>dq', '<cmd>lua DAPTerminate()<CR>')
M.map('n', '<leader>d<space>', '<cmd>lua require("dap").continue()<CR>')
M.map('n', '<leader>db', '<cmd>lua require("dap").toggle_breakpoint()<CR>')
M.map('n', '<leader>dn', '<cmd>lua require("dap").step_over()<CR>')
M.map('n', '<leader>di', '<cmd>lua require("dap").step_in()<CR>')
M.map('n', '<leader>do', '<cmd>lua require("dap").step_out()<CR>')
M.map('n', '<leader>dr', '<cmd>lua require("dap").restart()<CR>')
M.map('n', '<leader>dh', '<cmd>lua require("dap").run_to_cursor()<CR>')
M.map('n', '<leader>dI', '<cmd>lua require("dap.ui.widgets").hover()<CR>')
M.map('n', '<leader>di', '<cmd>lua require("dap").step_into()<CR>')
M.map('n', '<leader>du', '<cmd>lua require("dap").up()<CR>')
M.map('n', '<leader>dU', '<cmd>lua require("dap").down()<CR>')
M.map('n', '<leader>dT', '<cmd>lua DebugLastTest()<CR>')

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

local fzf_lsp = require('fzf_lsp')

-- ---- LSPCONFIG ----
-- -- autojump to single reference
-- lsp.handlers["textDocument/references"] = function(_, result, ctx, config)
--   if not result or vim.tbl_isempty(result) then
--     vim.notify("No references found")
--   else
--     local client = lsp.get_client_by_id(ctx.client_id)
--     config = config or {}
--     local title = "References"
--     local items = util.locations_to_items(result, client.offset_encoding)

--     if #items == 2 then
--       vim.notify("autojump to single reference")
--       if items[1].lnum == vim.api.nvim_win_get_cursor(0)[1] then
--         vim.cmd("e " .. items[2].filename .. "|" .. items[2].lnum)
--       else
--         vim.cmd("e " .. items[1].filename .. "|" .. items[1].lnum)
--       end
--     else
--       if config.loclist then
--         vim.fn.setloclist(0, {}, " ", { title = title, items = items, context = ctx })
--         api.nvim_command("lopen")
--       elseif config.on_list then
--         assert(type(config.on_list) == "function", "on_list is not a function")
--         config.on_list({ title = title, items = items, context = ctx })
--       else
--         vim.fn.setqflist({}, " ", { title = title, items = items, context = ctx })
--         api.nvim_command("botright copen")
--       end
--     end
--   end
-- end

