return {
	{
		'stevearc/oil.nvim',
		opts = {
			view_options = {
				show_hidden = true,
			}
		},
		-- Optional dependencies
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
		lazy = true,
		cmd = { "Oil" },
		keys = {
			{ "<leader>fn", "<cmd>Oil<cr>", desc = "File Tree" },
		},
	},
	-- {
	-- 	"nvim-tree/nvim-tree.lua",
	-- 	dependencies = {
	-- 		'nvim-tree/nvim-web-devicons'
	-- 	},
	-- 	lazy = true,
	-- 	cmd = {
	-- 		"NvimTreeToggle",
	-- 		"NvimTreeFindFile",
	-- 		"NvimTreeFindFileToggle",
	-- 	},
	-- 	opts = {
	-- 		hijack_directories = {
	-- 			enable = true,
	-- 			auto_open = true,
	-- 		},
	-- 		view = {
	-- 			width = 70,
	-- 		},
	-- 	},
	-- 	init = function()
	-- 		-- vim.keymap.set('n', '<leader>fn', '<cmd>NvimTreeFindFileToggle<CR>')
	-- 		vim.api.nvim_create_autocmd("VimEnter", {
	-- 			pattern = "*",
	-- 			callback = function()
	-- 				if vim.fn.isdirectory(vim.fn.expand("%:p")) == 1 then
	-- 					require("nvim-tree.api").tree.open()
	-- 				end
	-- 			end,
	-- 		})
	-- 	end,
	-- },
}
