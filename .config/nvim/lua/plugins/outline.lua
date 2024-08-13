return {
  "hedyhli/outline.nvim",
  lazy = true,
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>fo", "<cmd>Outline<CR>", desc = "Outline" },
  },
  opts = {
    outline_window = {
      position = "left",
      auto_close = true,
      show_relative_numbers = true,
    },
  },
}
