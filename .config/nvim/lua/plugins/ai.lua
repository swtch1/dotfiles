return {
	{
		"Exafunction/codeium.vim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
		},
		config = function()
			vim.keymap.set("i", "<C-j>", function()
				return vim.fn["codeium#CycleCompletions"](1)
			end, { expr = true, silent = true })

			vim.keymap.set("i", "<C-k>", function()
				return vim.fn["codeium#CycleCompletions"](-1)
			end, { expr = true, silent = true })

			vim.keymap.set("i", "<C-a>", function()
				return vim.fn["codeium#Accept"]()
			end, { expr = true, silent = true })
		end,
	},
	{
		"greggh/claude-code.nvim",
		enabled = true,
		lazy = false,
		keys = {
			{ "<leader>an", "<cmd>ClaudeCode<cr>", mode = { "n" }, desc = "ClaudeCode new session" },
			{ "<leader>ac", "<cmd>ClaudeCodeContinue<cr>", mode = { "n" }, desc = "ClaudeCode continue last session" },
			{ "<leader>ar", "<cmd>ClaudeCodeResume<cr>", mode = { "n" }, desc = "ClaudeCode pick session" },
		},
		cmd = {
			"ClaudeCode",
			"ClaudeCodeContinue",
			"ClaudeCodeResume",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("claude-code").setup({
				command = "claude --mcp-config /Users/josh/.claude/mcp.json",
				keymaps = {
					toggle = {
						normal = false,
						terminal = false,
						variants = {
							continue = false,
							verbose = false,
						},
					},
					window_navigation = false,
					scrolling = false,
				},
				window = {
					split_ratio = 0.4,
					position = "leftabove vsplit", -- Position of the window: "botright", "topleft", "vertical", "rightbelow vsplit", etc.
					enter_insert = true,
					hide_numbers = false,
					hide_signcolumn = true,
				},
			})
		end,
	},
	{
		"coder/claudecode.nvim",
		enabled = false,
		config = true,
		keys = {
			{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
			{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
			{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
			{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
			{
				"<leader>as",
				"<cmd>ClaudeCodeTreeAdd<cr>",
				desc = "Add file",
				ft = { "NvimTree", "neo-tree", "oil" },
			},
		},
	},
	{
		enabled = false,
		"yetone/avante.nvim",
		lazy = true,
		keys = {
			{
				"<leader>af",
				function()
					require("avante.api").focus()
				end,
				mode = { "n" },
				desc = "Avante: focus",
			},
			{ "<leader>aa", "<cmd>AvanteToggle<cr>", mode = { "n" }, desc = "Avante: toggle" },
			{
				"<leader>ab",
				function()
					local sidebar, _, _ = require("avante").get()
					if sidebar and sidebar:is_open() and sidebar.file_selector then
						if sidebar.file_selector:add_current_buffer() then
							vim.notify(
								"Added current buffer to file selector",
								vim.log.levels.DEBUG,
								{ title = "Avante" }
							)
						else
							vim.notify("Failed to add current buffer", vim.log.levels.WARN, { title = "Avante" })
						end
					else
						vim.notify(
							"Avante sidebar is not open or file selector not available",
							vim.log.levels.WARN,
							{ title = "Avante" }
						)
					end
				end,
				mode = { "n" },
				desc = "Avante: add current buffer",
			},
			{
				"<leader>aB",
				function()
					require("avante.api").add_buffer_files()
				end,
				mode = { "n" },
				desc = "Avante: add all buffers",
			},
		},
		opts = {
			---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
			provider = "gemini",
			gemini = {
				model = "gemini-2.5-pro-preview-05-06",
				max_tokens = 8192,
				api_key_name = "GEMINI_API_KEY",
			},
			-- provider = "claude",
			-- claude = {
			-- 	max_tokens = 8192,
			-- 	api_key_name = "ANTHROPIC_API_KEY",
			-- },
			-- provider = "openai",
			-- openai = {
			-- 	endpoint = "https://api.openai.com/v1",
			-- 	model = "gpt-4o",
			-- 	timeout = 60000, -- milliseconds
			-- 	temperature = 0,
			-- 	-- max_tokens = 4096,
			-- 	api_key_name = "OPENAI_API_KEY",
			-- },
			-- auto_suggestions_provider = "openai", -- Since auto-suggestions are a high-frequency operation and therefore expensive, it is recommended to specify an inexpensive provider or even a free provider: copilot
			behaviour = {
				auto_suggestions = false, -- Experimental stage
				auto_set_highlight_group = true,
				auto_set_keymaps = false, -- Disable default keymaps
				auto_apply_diff_after_generation = false,
				support_paste_from_clipboard = false,
			},
			mappings = {
				--- @class AvanteConflictMappings
				diff = {
					ours = "co",
					theirs = "ct",
					all_theirs = "ca",
					both = "cb",
					cursor = "cc",
					next = "]x",
					prev = "[x",
				},
				suggestion = {
					accept = "<M-l>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
				jump = {
					next = "]]",
					prev = "[[",
				},
				submit = {
					normal = "<CR>",
					insert = "<C-s>",
				},
				sidebar = {
					apply_all = "A",
					apply_cursor = "a",
					switch_windows = "<Tab>",
					reverse_switch_windows = "<S-Tab>",
				},
			},
			hints = { enabled = false },
			windows = {
				---@type "right" | "left" | "top" | "bottom"
				position = "right", -- the position of the sidebar
				wrap = true, -- similar to vim.o.wrap
				width = 30, -- default % based on available width
				sidebar_header = {
					enabled = true, -- true, false to enable/disable the header
					align = "center", -- left, center, right for title
					rounded = true,
				},
				input = {
					prefix = "> ",
					height = 8, -- Height of the input window in vertical layout
				},
				edit = {
					border = "rounded",
					start_insert = true, -- Start insert mode when opening the edit window
				},
				ask = {
					floating = false, -- Open the 'AvanteAsk' prompt in a floating window
					start_insert = true, -- Start insert mode when opening the ask window
					border = "rounded",
					---@type "ours" | "theirs"
					focus_on_apply = "ours", -- which diff to focus after applying
				},
			},
			highlights = {
				---@type AvanteConflictHighlights
				diff = {
					current = "DiffText",
					incoming = "DiffAdd",
				},
			},
			--- @class AvanteConflictUserConfig
			diff = {
				autojump = true,
				---@type string | fun(): any
				list_opener = "copen",
				--- Override the 'timeoutlen' setting while hovering over a diff (see :help timeoutlen).
				--- Helps to avoid entering operator-pending mode with diff mappings starting with `c`.
				--- Disable by setting to -1.
				override_timeoutlen = 500,
			},
			file_selector = {
				provider = "native",
				-- provider = "telescope",
			},
		},
		-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
		build = "make",
		-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below dependencies are optional,
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			-- "zbirenbaum/copilot.lua",   -- for providers='copilot'
			"MeanderingProgrammer/render-markdown.nvim",
		},
	},
	{
		"olimorris/codecompanion.nvim",
		enabled = false,
		lazy = true,
		cmd = {
			"CodeCompanion",
			"CodeCompanionActions",
			"CodeCompanionChat",
			"CodeCompanionCmd",
		},
		keys = {
			-- { "<leader>ac", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanionActions" },
			{ "<leader>aC", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanionChat" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			local default_dapter = "gemini"

			require("codecompanion").setup({
				adapters = {
					openai = function()
						return require("codecompanion.adapters").extend("openai", {
							schema = {
								max_completion_tokens = {
									default = 999999999999,
								},
								model = {
									default = "o1-2024-12-17",
								},
							},
						})
					end,

					gemini = function()
						return require("codecompanion.adapters").extend("gemini", {
							schema = {
								api_key = {
									default = os.getenv("GEMINI_API_KEY") or "",
								},
								model = {
									default = "gemini-2.5-pro-preview-05-06",
									-- default = "gemini-2.0-flash-thinking-exp-01-21",
								},
							},
						})
					end,
				},
				strategies = {
					chat = {
						adapter = default_dapter,
					},
					inline = {
						adapter = default_dapter,
					},
					cmd = {
						adapter = default_dapter,
					},
					workflow = {
						adapter = default_dapter,
					},
				},
			})
		end,
	},
}
