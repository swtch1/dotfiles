return {
	{
		'tpope/vim-fugitive',
		dependencies = { 'shumphrey/fugitive-gitlab.vim' },
	},
	{ 'shumphrey/fugitive-gitlab.vim' },
	{
		'junegunn/gv.vim',
		lazy = true,
		cmd = 'GV',
	},
	{
		'lewis6991/gitsigns.nvim',
		config = function()
			require('gitsigns').setup({
				attach_to_untracked = true,
				-- highlight differences within a hunk
				word_diff = false,

				on_attach = function()
					local gs = package.loaded.gitsigns

					-- Actions
					vim.keymap.set('n', '<leader>cc', gs.next_hunk, { desc = 'next hunk' })
					vim.keymap.set('n', '<leader>cC', gs.prev_hunk, { desc = 'previous hunk' })
					vim.keymap.set('n', '<leader>cs', gs.stage_hunk, { desc = 'stage hunk' })
					vim.keymap.set('n', '<leader>cu', gs.reset_hunk, { desc = 'reset hunk' })
					vim.keymap.set('v',
						'<leader>cs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
						{ desc = 'stage hunk' })
					vim.keymap.set('v',
						'<leader>cu', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
						{ desc = 'reset hunk' })
					vim.keymap.set('n', '<leader>cd', gs.preview_hunk, { desc = 'preview hunk' })
				end
			})
		end
	},
	{
		'sindrets/diffview.nvim',
		lazy = true,
		cmd = {
			"DiffviewOpen",
			"DiffviewFileHistory",
		},
	},
}
