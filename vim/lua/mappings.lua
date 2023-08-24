local vim = vim
local api = vim.api
local fn = vim.fn

local M = {}
-- map helper
function M.map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend('force', options, opts) end
  api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.nnoremap <silent> <Leader> :WhichKey '<Space>'<CR>
vim.vnoremap <silent> <Leader> :WhichKeyVisual '<Space>'<CR>

