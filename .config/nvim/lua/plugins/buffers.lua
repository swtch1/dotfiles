return {
	-- manage buffers
	{
		"jeetsukumaran/vim-buffergator",
		lazy = true,
		cmd = "BuffergatorOpen",
	},
	-- auto adjust buffer size
	{
		"anuvyklack/windows.nvim",
		-- adding keys breaks it on startup!?
		-- keys = {
		-- 	{ "<leader>fa", "<cmd>WindowsMaximize<cr>", desc = "Maximize window" },
		-- 	{ "<leader>fw", "<cmd>WindowsEqualize<cr>", desc = "Equalize windows" },
		-- },
		dependencies = {
			"anuvyklack/middleclass",
			"anuvyklack/animation.nvim",
		},
		config = function()
			vim.o.winwidth = 10 -- suggested minimum width for any buffer
			vim.o.winminwidth = 5 -- absolute minimum width for any buffer
			vim.o.equalalways = false
			require("windows").setup({
				autowidth = {
					enable = true,
					winwidth = 1.65, -- value between 1 and 2 to set the width of the active buffer
					filetype = {
						help = 2,
					},
				},
				ignore = {
					buftype = { "quickfix", "nofile" },
					filetype = { "NvimTree", "neo-tree", "undotree", "fugitive", "gundo", "" },
				},
				animation = {
					enable = false,
					duration = 100,
					fps = 30,
					easing = "in_out_sine",
				},
			})
		end,
	},
	-- move buffers around
	{
		"sindrets/winshift.nvim",
		lazy = true,
		cmd = "WinShift",
	},
	-- better quickfix menu
	{
		"kevinhwang91/nvim-bqf",
		opts = {
			preview = {
				win_height = 50,
			},
		},
	},
}
