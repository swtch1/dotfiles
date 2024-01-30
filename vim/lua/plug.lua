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
    vim.o.winwidth = 10   -- suggested minimum width for any buffer
    vim.o.winminwidth = 5 -- absolute minimum width for any buffer
    vim.o.equalalways = false
    require('windows').setup({
   autowidth = {
      enable = true,
      winwidth = 1.55, -- value between 1 and 2 to set the width of the active buffer
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
    separator = ' > ',
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
     inactive_sections = {
       lualine_a = {},
       lualine_b = {},
       lualine_c = {{ 'filename', path = 1, shorting_target = 5 }},
       lualine_x = {},
       lualine_y = {},
       lualine_z = {}
   },
   extensions = { 'fzf' },
 }

require('bqf').setup{
  preview = {
    win_height = 50,
  }
}

require('gitsigns').setup {
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Actions
    map('n', '<leader>cc', gs.next_hunk)
    map('n', '<leader>cC', gs.prev_hunk)
    map('n', '<leader>cs', gs.stage_hunk)
    map('n', '<leader>cu', gs.reset_hunk)
    map('v', '<leader>cs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
    map('v', '<leader>cu', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
    -- map('n', '<leader>hS', gs.stage_buffer)
    -- map('n', '<leader>hu', gs.undo_stage_hunk)
    -- map('n', '<leader>hR', gs.reset_buffer)
    map('n', '<leader>cd', gs.preview_hunk)
    -- map('n', '<leader>hb', function() gs.blame_line{full=true} end)
    -- map('n', '<leader>tb', gs.toggle_current_line_blame)
    -- map('n', '<leader>hd', gs.diffthis)
    -- map('n', '<leader>hD', function() gs.diffthis('~') end)
    -- map('n', '<leader>td', gs.toggle_deleted)

    -- Text object
    map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
  end
}

