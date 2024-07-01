set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

lua require('debug')
lua require("plug")
lua require("lsp")
lua require("codeium")
lua require("colorscheme")
lua require("treesitter")
lua require("plug")
" lua require("goc")

