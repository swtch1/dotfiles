return {
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			'nvim-tree/nvim-web-devicons'
		},
		lazy = true,
		cmd = {
			"NvimTreeToggle",
			"NvimTreeFindFile",
			"NvimTreeFindFileToggle",
		},
		opts = {
			hijack_directories = {
				enable = true,
				auto_open = true,
			},
			view = {
				width = 70,
			},
		},
		init = function()
			vim.keymap.set('n', '<leader>fn', '<cmd>NvimTreeFindFileToggle<CR>')
			vim.api.nvim_create_autocmd("VimEnter", {
				pattern = "*",
				callback = function()
					if vim.fn.isdirectory(vim.fn.expand("%:p")) == 1 then
						require("nvim-tree.api").tree.open()
					end
				end,
			})
		end,
	},
}
