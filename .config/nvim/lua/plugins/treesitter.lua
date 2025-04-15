return {
	--  {'nvim-treesitter/nvim-treesitter', opts={'do': ':TSUpdate'}},
	{
		'nvim-treesitter/nvim-treesitter',
		opts = {
			-- Automatically install missing parsers when entering buffer
			auto_install = true,

			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
		},
	},
	{ 'nvim-treesitter/playground' },
}
