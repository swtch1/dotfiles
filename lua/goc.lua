-- ref: https://alpha2phi.medium.com/writing-neovim-plugins-a-beginner-guide-part-i-e169d5fd1a58
-- ref: https://github.com/rafaelsq/nvim-goc.lua/blob/master/lua/nvim-goc.lua

local vim = vim
local ts_utils = require "nvim-treesitter.ts_utils"

local M = {
  hi = vim.api.nvim_create_namespace("goc"),
}

M.Show = function()
  print("hi")
end
