return {
	{
		"skywind3000/vim-terminal-help",
		dependencies = {
			"skywind3000/asyncrun.vim",
		},
		lazy = true,
		cmd = "AsyncRun",
		keys = {
			{ "<C-h>" },
			{ "<leader>R", "<cmd>AsyncRun -mode=term -pos=thelp <cr>", mode = { "n", "v" }, desc = "ctrl-c terminal" },
		},
		init = function()
			vim.g.terminal_key = "<c-h>"
			vim.g.terminal_height = 25
			vim.g.terminal_pos = "topleft"
			vim.g.terminal_close = 1
			-- kill session when exiting vim
			vim.g.terminal_kill = "term"
			vim.g.terminal_cwd = 0
			-- hide terminal in buffers list
			vim.g.terminal_list = 0
		end,
	},
}
