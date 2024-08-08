set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" lua require('plug')
lua require('debug')
lua require('config.vim')
lua require('config.lazy')
lua require('lsp')
" lua require('goc')

