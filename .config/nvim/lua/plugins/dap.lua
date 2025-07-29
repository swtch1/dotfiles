-- env vars, with defaults so lua doesn't complain
local app_url = os.getenv("SPEEDSCALE_APP_URL") or ""
local api_key = os.getenv("SPEEDSCALE_API_KEY") or ""
local tenant_id = os.getenv("TENANT_ID") or ""
local tenant_bucket = os.getenv("TENANT_BUCKET") or ""
local analyzer_report_id = os.getenv("ANALYZER_REPORT_ID") or ""
local snapshot_id = os.getenv("SNAPSHOT_ID") or ""
local config = os.getenv("CONFIG") or ""
local debug_port = 38697
local last_debug_args = nil

function ConfigureDapAdapters()
	local dap = require("dap")
	dap.adapters.go = function(callback)
		local stdout = vim.loop.new_pipe(false)
		local handle
		local pid_or_err
		-- opts are passed to "executable" dap field
		local opts = {
			stdio = { nil, stdout },
			args = { "dap", "-l", "127.0.0.1:" .. debug_port },
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
				port = debug_port,
				options = {
					initialize_timeout_sec = 60,
				},
			})
		end, 100)
	end

	dap.configurations.go = {
		{
			name = "analyzer - prompt",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/analyzer/",
			args = function()
				local user_args = {}
				local user_input = vim.fn.input("analyzer args: ")
				for word in string.gmatch(user_input, "[^%s]+") do
					table.insert(user_args, word)
				end
				-- store the computed args for DapRunLast
				last_debug_args = user_args
				return user_args
			end,
		},
		{
			name = "analyzer - report - from raw - s3",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/analyzer/",
			args = {
				"report",
				"analyze",
				"--app-url",
				app_url,
				"--api-key",
				api_key,
				"--notify-tenant",
				tenant_id,
				"--report",
				"s3://" .. tenant_bucket .. "/default/reports/" .. analyzer_report_id .. ".json",
				"--artifact-src",
				"s3://" .. tenant_bucket .. "/default",
				"--bucket",
				tenant_bucket,
				"--output-dir",
				".",
				"--reanalyze",
			},
		},
		{
			name = "analyzer - report - from raw - local reanalyze",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/analyzer/",
			args = {
				"report",
				"analyze",
				"--app-url",
				app_url,
				"--api-key",
				api_key,
				"--notify-tenant",
				tenant_id,
				"--report",
				"/Users/josh/.speedscale/data/reports/" .. analyzer_report_id .. ".json",
				"--bucket",
				tenant_bucket,
				"--artifact-src",
				"/Users/josh/.speedscale/data/reports/" .. analyzer_report_id,
				"--output-dir",
				".",
				"--reanalyze",
			},
		},
		{
			name = "analyzer - report - recreate",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/analyzer/",
			args = {
				"report",
				"analyze",
				"--app-url",
				app_url,
				"--api-key",
				api_key,
				"--notify-tenant",
				tenant_id,
				"--report",
				"s3://" .. tenant_bucket .. "/default/reports/" .. analyzer_report_id .. ".json",
				"--bucket",
				tenant_bucket,
				"--artifact-src",
				"/Users/josh/.speedscale/data/reports/" .. analyzer_report_id,
				"--output-dir",
				".",
				"--local",
				"--rm",
				"--recreate",
				"--reanalyze",
			},
		},
		{
			name = "analyzer - snapshot - s3select",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/analyzer/",
			args = {
				"snapshot",
				"--app-url",
				app_url,
				"--api-key",
				api_key,
				"--snapshot",
				"s3://" .. tenant_bucket .. "/default/scenarios/" .. snapshot_id .. ".json",
				"--output-dir",
				"./out",
				"--recreate",
			},
		},
		{
			name = "analyzer - snapshot - from raw file",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/analyzer/",
			args = {
				"snapshot",
				"--app-url",
				app_url,
				"--api-key",
				api_key,
				"--snapshot",
				"s3://" .. tenant_bucket .. "/default/scenarios/" .. snapshot_id .. ".json",
				"--output-dir",
				"./out",
				"--recreate",
				-- "--ignore-in-svc", "frontend:8080",
			},
		},
		{
			name = "analyzer - snapshot - local",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/analyzer/",
			args = {
				"snapshot",
				"--app-url",
				app_url,
				"--api-key",
				api_key,
				"--snapshot",
				"/Users/josh/.speedscale/data/snapshots/" .. snapshot_id .. ".json",
				"--raw",
				"/Users/josh/.speedscale/data/snapshots/" .. snapshot_id .. "/raw.jsonl",
				"--output-dir",
				"./snapshot",
				"--upload-to",
				"s3://" .. tenant_bucket,
				"--rm",
			},
		},
		{
			name = "analyzer - transform - local",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/analyzer/",
			args = {
				"transform",
				"--app-url",
				app_url,
				"--api-key",
				api_key,
				"--snapshot",
				"/Users/josh/.speedscale/data/snapshots/" .. snapshot_id .. ".json",
				"--output-dir",
				"./out",
				"--upload-to",
				"s3://" .. tenant_bucket .. "/default/scenarios/",
			},
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
			name = "k6",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/main.go",
			args = {
				"run",
				"test.js",
			},
		},
		{
			name = "operator",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/operator/",
		},
		{
			name = "proxymock - prompt",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/speedctl/cmd/proxymock",
			args = function()
				-- always use config
				local user_args = { "--config", config }

				local user_input = vim.fn.input("proxymock args: ")
				for word in string.gmatch(user_input, "[^%s]+") do
					table.insert(user_args, word)
				end
				-- store the computed args for DapRunLast
				last_debug_args = user_args
				return last_debug_args
			end,
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
				"--tags",
				"collector=v2.1.344",
				"--tags",
				"forwarder=v2.1.344",
				"--tags",
				"generator=v2.1.344",
				"--tags",
				"goproxy=v2.1.344",
				"--tags",
				"inspector=v2.1.344",
				"--tags",
				"operator=v2.1.344",
				"--tags",
				"responder=v2.1.344",
				"--tags",
				"speedscale-cli=v2.1.344",
				"--speedctl=v2.1.344",
				"--kustomize",
				"../../kraken/master/k8s/v2/",
				"--tracking-tag=jmt-kraken",
				"--speedscale-home-path",
				"/Users/josh/.speedscale",
				"--cluster-name=jmt-dev",
				"--timeout=20m",
				"--operator=false",
				"--istio-install=false",
				"--istio-inject=false",
				"--env-teardown=false",
				"--deployment-name=notifications",
				"--invert=false",
				"--validate-dlp=false",
				"--validate-replays",
				"urlgoals=39010415-958c-42a7-88f1-852c6dc7d22e:kraken-notifications-latest-urlgoals",
				"--verbose",
				"--test-teardown=false", -- delete deployment after test
				"--snapshot-capture-for=60s",
			},
		},
		{
			name = "speedctl - prompt",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/speedctl/cmd/speedctl",
			args = function()
				-- always use config
				local user_args = { "--config", config }

				local user_input = vim.fn.input("speedctl args: ")
				for word in string.gmatch(user_input, "[^%s]+") do
					table.insert(user_args, word)
				end
				-- store the computed args for DapRunLast
				last_debug_args = user_args
				return last_debug_args
			end,
		},
		{
			name = "speedctl - replay",
			type = "go",
			request = "launch",
			program = vim.fn.getcwd() .. "/speedctl/cmd/speedctl",
			args = {
				"--config",
				config,
				"replay",
				snapshot_id,
				"--test-config-id",
				"regression_no_mocks",
				"--mode",
				"tests-only",
				"--custom-url",
				"http://localhost:8080", -- HTTP
				-- "--custom-url", "localhost:5555", -- gRPC
			},
		},
		{
			name = "< attach >",
			type = "go",
			request = "attach",
			mode = "remote",
			host = "127.0.0.1",
			port = debug_port,
		},
	}
end

return {
	{
		{
			"miroshQa/debugmaster.nvim",
			enabled = false,
			-- osv is needed if you want to debug neovim lua code. Also can be used
			-- as a way to quickly test-drive the plugin without configuring debug adapters
			dependencies = { "mfussenegger/nvim-dap", "jbyuki/one-small-step-for-vimkind" },
			config = function()
				local dm = require("debugmaster")
				-- make sure you don't have any other keymaps that starts with "<leader>d" to avoid delay
				-- Alternative keybindings to "<leader>d" could be: "<leader>m", "<leader>;"
				vim.keymap.set({ "n", "v" }, "<leader>d", dm.mode.toggle, { nowait = true })
				-- If you want to disable debug mode in addition to leader+d using the Escape key:
				-- vim.keymap.set("n", "<Esc>", dm.mode.disable)
				-- This might be unwanted if you already use Esc for ":noh"
				vim.keymap.set("t", "<C-\\>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

				dm.plugins.osv_integration.enabled = true -- needed if you want to debug neovim lua code
				ConfigureDapAdapters()
			end,
		},
	},
	{
		"rcarriga/nvim-dap-ui",
		enabled = true,
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
			"leoluz/nvim-dap-go",
		},
		config = function()
			ConfigureDapAdapters()

			local vim = vim
			local dap = require("dap")
			local dap_ui = require("dapui")
			local dap_go = require("dap-go")

			function DAPRun()
				-- reset so we can use a different debug config
				last_debug_args = nil

				dap.continue()
				dap_ui.open()
			end

			function DapRunLast()
				if last_debug_args then
					-- if we have stored args from the prompt config, use them
					local program_path = vim.fn.getcwd() .. "/speedctl/cmd/speedctl"
					local temp_config = {
						name = "speedctl - (last prompted args)", -- Dynamic name for clarity
						type = "go",
						request = "launch",
						program = program_path,
						args = last_debug_args, -- use the stored arguments
					}
					require("dap").run(temp_config)
				else
					-- otherwise, use the default run_last behavior
					require("dap").run_last()
				end
				require("dapui").open()
			end

			function DAPTerminate()
				dap.terminate()
				dap_ui.close()
			end

			function DebugTest()
				dap_go.debug_test()
				dap_ui.open()
			end

			function DebugLastTest()
				dap_go.debug_last_test()
				dap_ui.open()
			end

			vim.keymap.set("n", "<leader>dd", "<cmd>lua DAPRun()<CR>")
			vim.keymap.set("n", "<leader>dD", "<cmd>lua DapRunLast()<CR>")
			vim.keymap.set("n", "<leader>dq", "<cmd>lua DAPTerminate()<CR>")
			vim.keymap.set("n", "<leader>d<space>", '<cmd>lua require("dap").continue()<CR>')
			vim.keymap.set("n", "<leader>db", '<cmd>lua require("dap").toggle_breakpoint()<CR>')
			vim.keymap.set("n", "<leader>dn", '<cmd>lua require("dap").step_over()<CR>')
			vim.keymap.set("n", "<leader>di", '<cmd>lua require("dap").step_in()<CR>')
			vim.keymap.set("n", "<leader>do", '<cmd>lua require("dap").step_out()<CR>')
			vim.keymap.set("n", "<leader>dr", '<cmd>lua require("dap").restart()<CR>')
			vim.keymap.set("n", "<leader>dh", '<cmd>lua require("dap").run_to_cursor()<CR>')
			vim.keymap.set("n", "<leader>dI", '<cmd>lua require("dap.ui.widgets").hover()<CR>')
			vim.keymap.set("n", "<leader>di", '<cmd>lua require("dap").step_into()<CR>')
			vim.keymap.set("n", "<leader>du", '<cmd>lua require("dap").up()<CR>')
			vim.keymap.set("n", "<leader>dU", '<cmd>lua require("dap").down()<CR>')
			vim.keymap.set("n", "<leader>dt", "<cmd>lua DebugTest()<CR>")
			vim.keymap.set("n", "<leader>dT", "<cmd>lua DebugLastTest()<CR>")

			dap_ui.setup({
				force_buffers = true,
				-- Layouts define sections of the screen to place windows.
				-- The position can be "left", "right", "top" or "bottom".
				-- The size specifies the height/width depending on position. It can be an Int
				-- or a Float. Integer specifies height/width directly (i.e. 20 lines/columns) while
				-- Float value specifies percentage (i.e. 0.3 - 30% of available lines/columns)
				-- Elements are the elements shown in the layout (in order).
				-- Layouts are opened in order so that earlier layouts take priority in window sizing.
				layouts = {
					{
						elements = {
							{ id = "breakpoints", size = 0.25 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
							{ id = "scopes", size = 0.25 },
						},
						position = "left",
						size = 40,
					},
					{
						elements = { { id = "repl", size = 0.9 } },
						position = "bottom",
						size = 20,
					},
				},
				render = {
					indent = 1,
					max_value_lines = 1000,
					max_type_length = nil, -- Can be integer or nil.
				},

				icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
				mappings = {
					-- Use a table to apply multiple mappings
					expand = { "<CR>", "<2-LeftMouse>" },
					open = "o",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				controls = {
					enabled = true,
					-- Display controls in this element
					element = "repl",
					icons = {
						pause = "󰏤",
						play = "",
						step_into = "",
						step_over = "",
						step_out = "",
						step_back = "",
						run_last = "↻",
						terminate = "󰓛",
					},
				},
				floating = {
					max_height = nil, -- These can be integers or a float between 0 and 1.
					max_width = nil, -- Floats will be treated as percentage of your screen.
					border = "single", -- Border style. Can be "single", "double" or "rounded"
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
				windows = { indent = 1 },
			})
		end,
	},
	{
		"leoluz/nvim-dap-go",
		lazy = true,
		ft = { "go" },
	},
}
