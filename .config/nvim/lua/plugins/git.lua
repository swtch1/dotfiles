return {
  {
    'tpope/vim-fugitive',
  },
  {
    'shumphrey/fugitive-gitlab.vim',
    dependencies = { 'tpope/vim-fugitive' },
    lazy = true,
    cmd = 'GBrowse',
  },
  {
    'junegunn/gv.vim',
    lazy = true,
    cmd = 'GV',
  },
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        on_attach = function()
          local gs = package.loaded.gitsigns

          -- Actions
          vim.keymap.set('n', '<leader>cc', gs.next_hunk)
          vim.keymap.set('n', '<leader>cC', gs.prev_hunk)
          vim.keymap.set('n', '<leader>cs', gs.stage_hunk)
          vim.keymap.set('n', '<leader>cu', gs.reset_hunk)
          vim.keymap.set('v', '<leader>cs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          vim.keymap.set('v', '<leader>cu', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
          vim.keymap.set('n', '<leader>cd', gs.preview_hunk)

          -- Text object
          vim.keymap.set({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
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
