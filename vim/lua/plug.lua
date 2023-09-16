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
