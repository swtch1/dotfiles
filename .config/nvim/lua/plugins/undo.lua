return {
  {
    'mbbill/undotree',
    lazy = true,
    cmd = {
      'UndotreeToggle',
      'UndotreeFocus',
      'UndotreeShow',
      'UndotreeHide',
    }
  },
  {
    'tzachar/highlight-undo.nvim',
    opts = {
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
    }
  },
}
