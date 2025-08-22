set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

lua require('config.debug')
lua require('config.vim')
lua require('config.lazy')
lua require('config.lsp')
" lua require('custom.goc')

" cursor shape changes for insert mode
set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50

