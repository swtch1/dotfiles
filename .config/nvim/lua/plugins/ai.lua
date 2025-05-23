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
		-- testing Aider plugins
		enabled = false,
		"joshuavial/aider.nvim",
		opts = {
			-- your configuration comes here
			-- if you don't want to use the default settings
			args = {
				"--no-auto-commits",
				"--watch",
				"--read",
				"../.aider/INSTRUCTIONS.md",
				"--cache-keepalive-pings",
				"1",
				"--model",
				"gemini/gemini-2.5-pro-preview-03-25",
			},
			auto_manage_context = true, -- automatically manage buffer context
			default_bindings = true, -- use default <leader>A keybindings
			debug = false, -- enable debug logging
		},
	},
	{
		-- testing Aider plugins
		enabled = false,
		"nekowasabi/aider.vim",
		dependencies = "vim-denops/denops.vim",
		config = function()
			vim.g.aider_command = "aider "
				.. "--model gemini/gemini-2.5-pro-preview-03-25 "
				.. "--no-auto-commits "
				.. "--auto-accept-architect false "
				.. "--watch "
				.. "--read ../.aider/INSTRUCTIONS.md "
				.. "--cache-keepalive-pings 1 "
			vim.g.aider_buffer_open_type = "vsplit"
			vim.g.aider_floatwin_width = 300
			vim.g.aider_floatwin_height = 50

			vim.api.nvim_create_autocmd("User", {
				pattern = "AiderOpen",
				callback = function(args)
					vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = args.buf })
					vim.keymap.set("n", "<Esc>", "<cmd>AiderHide<CR>", { buffer = args.buf })
				end,
			})
			vim.api.nvim_set_keymap("n", "<leader>at", ":AiderRun<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>aa", ":AiderAddCurrentFile<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap(
				"n",
				"<leader>ar",
				":AiderAddCurrentFileReadOnly<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap("n", "<leader>aw", ":AiderAddWeb<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>ax", ":AiderExit<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap(
				"n",
				"<leader>ai",
				":AiderAddIgnoreCurrentFile<CR>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap("n", "<leader>aI", ":AiderOpenIgnore<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>aI", ":AiderPaste<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap("n", "<leader>ah", ":AiderHide<CR>", { noremap = true, silent = true })
			vim.api.nvim_set_keymap(
				"v",
				"<leader>av",
				":AiderVisualTextWithPrompt<CR>",
				{ noremap = true, silent = true }
			)
		end,
	},
	{
		-- testing Aider plugins
		enabled = false,
		"GeorgesAlkhouri/nvim-aider",
		cmd = {
			"AiderTerminalToggle",
			"AiderHealth",
		},
		keys = {
			{ "<leader>a/", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
			{
				"<leader>as",
				"<cmd>AiderTerminalSend<cr>",
				desc = "Send to Aider",
				mode = { "n", "v" },
			},
			{ "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
			{ "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
			{ "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
			{ "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
			{ "<leader>ar", "<cmd>AiderQuickReadOnlyFile<cr>", desc = "Add File as Read-Only" },
			-- Example nvim-tree.lua integration if needed
			{
				"<leader>a+",
				"<cmd>AiderTreeAddFile<cr>",
				desc = "Add File from Tree to Aider",
				ft = "NvimTree",
			},
			{
				"<leader>a-",
				"<cmd>AiderTreeDropFile<cr>",
				desc = "Drop File from Tree from Aider",
				ft = "NvimTree",
			},
		},
		dependencies = {
			"folke/snacks.nvim",
			--- The below dependencies are optional
			"catppuccin/nvim",
			"nvim-tree/nvim-tree.lua",
			--- Neo-tree integration
			{
				"nvim-neo-tree/neo-tree.nvim",
				opts = function(_, opts)
					-- Example mapping configuration (already set by default)
					-- opts.window = {
					--   mappings = {
					--     ["+"] = { "nvim_aider_add", desc = "add to aider" },
					--     ["-"] = { "nvim_aider_drop", desc = "drop from aider" }
					--   }
					-- }
					require("nvim_aider.neo_tree").setup(opts)
				end,
			},
		},
		config = function()
			require("nvim_aider").setup({
				-- Command that executes Aider
				aider_cmd = "aider",
				-- Command line arguments passed to aider
				args = {
					"--no-auto-commits",
					"--watch",
					"--read",
					"../.aider/INSTRUCTIONS.md",
					"--cache-keepalive-pings",
					"1",
					"--model",
					"gemini/gemini-2.5-pro-preview-03-25",
				},
				-- Theme colors (automatically uses Catppuccin flavor if available)
				theme = {
					user_input_color = "#a6da95",
					tool_output_color = "#8aadf4",
					tool_error_color = "#ed8796",
					tool_warning_color = "#eed49f",
					assistant_output_color = "#c6a0f6",
					completion_menu_color = "#cad3f5",
					completion_menu_bg_color = "#24273a",
					completion_menu_current_color = "#181926",
					completion_menu_current_bg_color = "#f4dbd6",
				},
				-- snacks.picker.layout.Config configuration
				picker_cfg = {
					preset = "vscode",
				},
				-- Other snacks.terminal.Opts options
				config = {
					os = { editPreset = "nvim-remote" },
					gui = { nerdFontsVersion = "3" },
				},
				win = {
					wo = { winbar = "Aider" },
					style = "nvim_aider",
					position = "bottom",
				},
			})
		end,
	},
	{
		enabled = true,
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
				model = "gemini-2.5-pro-preview-03-25",
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
		lazy = true,
		cmd = {
			"CodeCompanion",
			"CodeCompanionActions",
			"CodeCompanionChat",
			"CodeCompanionCmd",
		},
		keys = {
			{ "<leader>ac", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanionActions" },
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
									default = "gemini-2.5-pro-exp-03-25",
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
