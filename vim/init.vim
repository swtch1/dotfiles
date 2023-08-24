set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

lua require("plug")
lua require("lsp")
lua require("goc")
lua require("codeium")
lua require("colorscheme")
" lua require("dap")
" lua require("treesitter_context")
" lua require("goc")
" lua require("plug")

