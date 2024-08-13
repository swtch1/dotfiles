return {
  "nvim-telescope/telescope.nvim",
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'BurntSushi/ripgrep', -- optional
    'sharkdp/fd',         -- optional
  },
  lazy = true,
  keys = {
    { '<leader>p', '<cmd>Telescope find_files<cr>' },
    { '<leader>P', ':lua require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })<CR>' },
    { '<leader>fa', '<cmd>Telescope live_grep<cr>' },
    { '<leader>fA', ':lua require("telescope.builtin").live_grep({ cwd = vim.fn.expand("%:p:h") })<CR>' },
    { '<leader>gu', ':lua require("telescope.builtin").lsp_implementations()<CR>' },
    { '<leader>gR', ':lua require("telescope.builtin").lsp_references()<CR>' },
    { '<leader>gT', ':lua require("telescope.builtin").lsp_incoming_calls()<CR>' },
  },
}
