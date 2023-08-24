local vim = vim

vim.g.startify_change_to_dir='0'
vim.g.startify_bookmarks = {
  { v = '~/.config/nvim/init.vim' },
  { z = '~/.zshrc'                },
}
vim.g.startify_enable_special='0'
vim.g.startify_lists = {
  { type = 'dir',       header = {'   MRU local' } },
  { type = 'files',     header = {'   MRU global'} },
  { type = 'sessions',  header = {'   Sessions'  } },
  { type = 'bookmarks', header = {'   Bookmarks' } },
  { type = 'commands',  header = {'   Commands'  } },
}

vim.api.nvim_set_keymap("n", "<silent>", "<leader> :WhichKey <space><CR>", { noremap = true})
vim.api.nvim_set_keymap("v", "<silent>", "<leader> :WhichKeyVisual <space><CR>", { noremap = true})

vim.g.fzf_buffers_jump = '1'
-- TODO: fix fzf select opts
-- vim.FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'
-- function! s:build_quickfix_list(lines)
--   call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
--   copen
--   cc
-- endfunction
-- TODO: fix fzf actions
-- vim.g.fzf_action = {
--    'ctrl-q': function('s:build_quickfix_list'),
--    'ctrl-t': 'tab split',
--    'ctrl-x': 'split',
--    'ctrl-v': 'vsplit' }

vim.g.tagbar_width='120'
vim.g.tagbar_position='topleft vertical'

