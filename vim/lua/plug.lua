require('glow').setup({
  height_ratio = 0.85,
})

require('highlight-undo').setup({
  duration = 1000,
  undo = {
    hlgroup = 'HighlightUndo',
    mode = 'n',
    lhs = 'u',
    map = 'undo',
    opts = {}
  },
  redo = {
    hlgroup = 'HighlightUndo',
    mode = 'n',
    lhs = '<C-r>',
    map = 'redo',
    opts = {}
  },
  highlight_for_count = true,
})

-- auto resize windows
function SetupWindowsNvim()
    vim.o.winwidth = 10
    vim.o.winminwidth = 8
    vim.o.equalalways = false
    require('windows').setup({
   autowidth = {
      enable = true,
      winwidth = 1.5,
      filetype = {
         help = 2,
      },
   },
   ignore = {
      buftype = { "quickfix" },
      filetype = { "NvimTree", "neo-tree", "undotree", "gundo" }
   },
   animation = {
      enable = false,
      duration = 100,
      fps = 30,
      easing = "in_out_sine"
   }
})
end
vim.cmd('autocmd VimEnter * lua SetupWindowsNvim()')

-- lualine
local navic = require("nvim-navic")
navic.setup{
 icons = {
        File          = "",
        Module        = "",
        Namespace     = "",
        Package       = "",
        Class         = "",
        Method        = "",
        Property      = "",
        Field         = "",
        Constructor   = "",
        Enum          = "",
        Interface     = "",
        Function      = "",
        Variable      = "",
        Constant      = "",
        String        = "",
        Number        = "",
        Boolean       = "",
        Array         = "",
        Object        = "",
        Key           = "",
        Null          = "",
        EnumMember    = "",
        Struct        = "",
        Event         = "",
        Operator      = "",
        TypeParameter = "",
    },
}

require('lualine').setup{
  options = {
    icons_enabled = false,
    theme = 'papercolor_light',
    component_separators = {'', ''},
    section_separators = {'', ''},
    disabled_filetypes = {}
   },
   sections = {
     lualine_a = { },
     lualine_b = {
       {
	 'filename',
	 path = 1 -- 0 = just filename, 1 = relative path, 2 = absolute path
       },
     },
     lualine_c = {
       {
	 function() return navic.get_location() end,
	 cond = navic.is_available
       },
     },
     lualine_x = { },
     lualine_y = { },
     lualine_z = { 'filetype' },
   },
   extensions = { 'fzf' },
 }
