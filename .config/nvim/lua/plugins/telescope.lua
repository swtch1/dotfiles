return {
  "nvim-telescope/telescope.nvim",
  init = function()
    vim.keymap.set('n', '<leader>p', '<cmd>Telescope find_files<cr>')
    vim.keymap.set('n', '<leader>p', '<cmd>Telescope find_files %<cr>')
  end
}
