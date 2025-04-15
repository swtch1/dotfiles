return {
	{
		-- icons
		"echasnovski/mini.nvim",
		version = false,
	},
	{
		-- more icons for some reason
		"nvim-tree/nvim-web-devicons",
		cmd = "NvimWebDeviconsHiTest",
		config = function()
			require("nvim-web-devicons").setup()
		end
	},
	{
		enabled = true,
		'ellisonleao/gruvbox.nvim',
		config = function()
			vim.o.background = 'dark'
			require('gruvbox').setup({
				contrast = '', -- soft / hard / empty string for middle
			})
			vim.cmd('colorscheme gruvbox')
		end
	},
	{
		'norcalli/nvim-colorizer.lua',
		config = function()
			require('colorizer').setup()
		end
	},
}
