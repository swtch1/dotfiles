return {
  'mhinz/vim-startify',
  init = function()
    vim.g.startify_change_to_dir = 0
    vim.g.startify_bookmarks = {
      { c = '~/.speedscale/config.yaml' },
      { v = '~/.vimrc' },
      { z = '~/.zshrc' }
    }
    vim.g.startify_enable_special = 0
    vim.g.startify_lists = {
      { type = 'dir', header = { '   MRU ' .. vim.fn.getcwd() } },
      { type = 'files', header = { '   MRU' } },
      { type = 'sessions', header = { '   Sessions' } },
      { type = 'bookmarks', header = { '   Bookmarks' } },
      { type = 'commands', header = { '   Commands' } }
    }
  end
}
