return {
	{
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
