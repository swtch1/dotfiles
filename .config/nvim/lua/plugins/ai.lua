return {
	{
		'Exafunction/codeium.vim',
		dependencies = {
			'nvim-lua/plenary.nvim',
			'hrsh7th/nvim-cmp',
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
		"David-Kunz/gen.nvim",
		opts = {
			model = "mistral",              -- The default model to use.
			quit_map = "q",                 -- set keymap for close the response window
			retry_map = "<c-r>",            -- set keymap to re-send the current prompt
			accept_map = "<c-cr>",          -- set keymap to replace the previous selection with the last result
			host = "localhost",             -- The host running the Ollama service.
			port = "11434",                 -- The port on which the Ollama service is listening.
			display_mode = "horizontal-split", -- The display mode. Can be "float" or "split" or "horizontal-split".
			show_prompt = false,            -- Shows the prompt submitted to Ollama.
			show_model = true,              -- Displays which model you are using at the beginning of your chat session.
			no_auto_close = true,           -- Never closes the window automatically.
			hidden = false,                 -- Hide the generation window (if true, will implicitly set `prompt.replace = true`), requires Neovim >= 0.10
			debug = false                   -- Prints errors and the command which is run.
		}
	},
	{
		"jackMort/ChatGPT.nvim",
		lazy = true,
		event = "VeryLazy",
		config = function()
			require("chatgpt").setup({
				-- assumes OPENAI_API_KEY env var
				openai_params = {
					-- NOTE: model can be a function returning the model name
					-- this is useful if you want to change the model on the fly
					-- using commands
					-- Example:
					-- model = function()
					--     if some_condition() then
					--         return "gpt-4-1106-preview"
					--     else
					--         return "gpt-3.5-turbo"
					--     end
					-- end,
					model = "gpt-4-1106-preview",
					frequency_penalty = 0,
					presence_penalty = 0,
					max_tokens = 4095,
					temperature = 0.2,
					top_p = 0.1,
					n = 1,
				}
			})
		end,
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim"
		}
	}
}
