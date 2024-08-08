return {
  'hedyhli/outline.nvim',
  lazy = true,
  cmd = "Outline",
  config = function()
    require("outline").setup()
  end
}
