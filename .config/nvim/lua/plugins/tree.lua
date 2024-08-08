return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      'nvim-tree/nvim-web-devicons'
    },
    lazy = true,
    cmd = {
      "NvimTreeToggle",
      "NvimTreeFindFile",
      "NvimTreeFindFileToggle",
    },
    opts = {
      view = {
        width = 70,
      },
    },
    init = function()
      vim.keymap.set('n', '<leader>fn', '<cmd>NvimTreeFindFileToggle<CR>')
    end,
  },
}

