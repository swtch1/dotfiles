local vim = vim
-- inspect local variables with `print("obj", inspect(obj))`
local inspect = require("vim.inspect")

---- NVIM-CMP ----
local cmp = require('cmp')
cmp.setup({
  -- don't guess at which option to select
  -- preselect = cmp.PreselectMode.None,
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

---- DEBUGGER ----
local dap = require('dap')
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
tenantBucket = os.getenv("TENANT_BUCKET") or ""
analyzerReportID = os.getenv("ANALYZER_REPORT_ID") or ""

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
      "replay", "2c47d647-0771-4a5d-b8d2-2f63c847077b", "--test-config-id", "jmt-dev-everlasting-generator", "--mode", "generator-only", "--custom-url", "127.0.0.1:8080"
    }
  },
  {
    name = "current file",
    type = "go",
    request = "launch",
    program = "${file}",
  },
  {
    name = "test dir",
    type = "go",
    request = "launch",
    mode = "test",
    program = "./${relativeFileDirname}",
    -- args = { -- doesn't seem to work - need to look at the docs
    --   "--run", "TestSendUtilizationMetrics"
    -- },
  },
}

dapui = require('dapui')
dapui.setup(
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
      }, {
        elements = { { id = "repl", size = 0.9 } },
        position = "bottom",
        size = 20
      } },
    render = {
      indent = 1,
      max_value_lines = 1000
    }
})

---- LSPCONFIG ----

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(_, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

    -- Mappings.
    local opts = { noremap=true, silent=true }

    -- LSP --
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', '<leader>gD', ':vsp<CR><Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<leader>gS', ':sp<CR><Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<leader>gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', '<leader>gp', '<C-T>', opts)
    buf_set_keymap('n', '<leader>gA', '<Cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', '<leader>gi', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', '<leader>gu', ':Implementations<CR>', opts)
    buf_set_keymap('n', '<leader>gU', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<leader>gy', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<leader>gn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<leader>gR', ':References<CR>', opts)
    buf_set_keymap('n', '<leader>gt', '<Cmd>lua vim.lsp.buf.incoming_calls()<CR>', opts)
    buf_set_keymap('n', '<leader>fd', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    buf_set_keymap('n', '<leader>a', ':DiagnosticsAll<CR>', opts)
    buf_set_keymap('n', '<leader>ra', ':CodeActions<CR>', opts)
    buf_set_keymap('n', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('i', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<leader>gO', '<Cmd>lua vim.lsp.buf.outgoing_calls()<CR>', opts)

    buf_set_keymap('n', '<leader>rl', '<cmd>lua vim.o.background="light"<CR>', opts)

    -- WORKSPACE --
    buf_set_keymap('n', '<leader>Wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<leader>Wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<leader>Wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)

    function DAPRun()
      -- vim.api.nvim_command('only')
      dap.continue()
      dapui.open()
    end
    buf_set_keymap('n', '<leader>dd', '<cmd>lua DAPRun()<CR>', opts)
    function DAPTerminate()
      dap.terminate()
      dapui.close()
    end
    buf_set_keymap('n', '<leader>dq', '<cmd>lua DAPTerminate()<CR>', opts)
    buf_set_keymap('n', '<leader>d<space>', '<cmd>lua require("dap").continue()<CR>', opts)
    buf_set_keymap('n', '<leader>db', '<cmd>lua require("dap").toggle_breakpoint()<CR>', opts)
    buf_set_keymap('n', '<leader>dn', '<cmd>lua require("dap").step_over()<CR>', opts)
    buf_set_keymap('n', '<leader>di', '<cmd>lua require("dap").step_in()<CR>', opts)
    buf_set_keymap('n', '<leader>do', '<cmd>lua require("dap").step_out()<CR>', opts)
    buf_set_keymap('n', '<leader>dr', '<cmd>lua require("dap").restart()<CR>', opts)
    buf_set_keymap('n', '<leader>dh', '<cmd>lua require("dap").run_to_cursor()<CR>', opts)
    buf_set_keymap('n', '<leader>dI', '<cmd>lua require("dap.ui.widgets").hover()<CR>', opts)
    buf_set_keymap('n', '<leader>di', '<cmd>lua require("dap").step_into()<CR>', opts)
    buf_set_keymap('n', '<leader>du', '<cmd>lua require("dap").up()<CR>', opts)
    buf_set_keymap('n', '<leader>dU', '<cmd>lua require("dap").down()<CR>', opts)
end

local requestedLSPServers = {
    gopls = {
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
    },
    bashls = {},
    clangd  = {},
    jedi_language_server = {},
    jsonls  = {},
    jdtls = {},
    rust_analyzer  = {},
    solargraph = {},
    sqlls  = {},
    tflint = {},
    tsserver = {},
    -- sumneko_lua = {}, -- mason.nvim should update this refrence at some point
    yamlls  = {
        settings = {
	    yaml = {
                keyOrdering = false,
                schemas = {
	            kubernetes = "*.yaml",
                    ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
                    ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = "*gitlab-ci*.{yml,yaml}",
                    ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*compose*.{yml,yaml}",
                    ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
                },
	    },
	},
    },
    zk = {},
    terraformls = {},
}

local lsp_installer = require("nvim-lsp-installer")
local cmp_lsp = require('cmp_nvim_lsp')
local lsp_installer_servers = require('nvim-lsp-installer.servers')
lsp_installer.settings({
    ui = {
        icons = {
            server_installed = "✓",
            server_pending = "➜",
            server_uninstalled = "✗"
        }
    }
})

for lsp, opts in pairs(requestedLSPServers) do
    local capabilities = cmp_lsp.default_capabilities(vim.lsp.protocol.make_client_capabilities())
    local available, lsp_server = lsp_installer_servers.get_server(lsp)
    opts["on_attach"] = on_attach
    opts["capabilities"] = capabilities
    opts["flags"] = { debounce_text_changes = 150 }
    if available and not lsp_server:is_installed() then
        lsp_server:install()
    end
    lsp_server:on_ready(function()
        lsp_server:setup(opts)
    end)
end

