set nocompatible
set nowrap
set number  " line numbers
set ignorecase " don't care about case in search
set smartcase
set hlsearch
set incsearch
set noswapfile
set title
set tabstop=2
set shiftwidth=2
set showcmd
set laststatus=2
set encoding=utf-8
set updatetime=100
set splitright
set timeoutlen=350 ttimeoutlen=0 " ms to wait before waiting for extra keys
set shortmess-=S " show count when searching
set shortmess+=c
set scrolloff=3
set visualbell
set history=10000
set wildignorecase
set number relativenumber
set hidden " allow navigating away from unsaved buffers
set completeopt=menuone,menu,longest,preview
set wildmenu
set wildmode=longest,list,full
set mouse=a
set foldlevel=99
" c auto-wraps comments
" r auto insert comment leader after <enter> in insert mode
" q allow formatting with gq
" n recognize number lists (line-wraps line up under the start of the text not the number)
" j remove comment leader after joining lines
" see :h fo-table for details
set formatoptions=rqnj
set textwidth=80

" allow backspace to delete indentation and inserted text
set backspace=indent,eol,start

" remap leader
let mapleader = "\<Space>"

" remember my buffers
exec 'set viminfo=%,' . &viminfo

" syntax highlighting for things that might have large data
set maxmempattern=1048576

" properly handle colors in tmux
set t_Co=256
set t_ut=

" persistent undo
if has('persistent_undo')
    set undodir=$HOME/.vim/undo
    set undolevels=10000
    set undofile
endif

" system clipboard
set clipboard=unnamed
if system('uname -s') == 'Linux'
    set clipboard=unnamedplus
endif

" speed things up
set lazyredraw
set ttyfast

" syntax highlighting
syntax on
filetype on
filetype plugin on

" nvim terminal
tnoremap <Esc> <C-\><C-n>

call plug#begin('~/.vim/plugged')

" Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
" Plug 'junegunn/fzf.vim'
let g:fzf_buffers_jump = 1
let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction
let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Plug 'tpope/vim-commentary'
nnoremap <Leader>/ :Commentary<CR><Esc>
vnoremap <Leader>/ :Commentary<CR><Esc>

" Plug 'SirVer/ultisnips'
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger='<c-j>'
let g:UltiSnipsJumpBackwardTrigger='<c-k>'
let g:UltiSnipsEditSplit='horizontal'
" Plug 'quangnguyen30192/cmp-nvim-ultisnips'

" Plug 'jeetsukumaran/vim-buffergator'
let g:buffergator_suppress_keymaps = 1
let g:buffergator_sort_regime = "mru"
let g:buffergator_show_full_directory_path = 0
let g:buffergator_vsplit_size = 60
let g:buffergator_viewport_split_policy = "L"

" Plug 'skywind3000/vim-terminal-help'
let g:terminal_key = "<c-h>"
let g:terminal_height = 25
let g:terminal_pos = "topleft"
let g:terminal_close = 1
let g:terminal_cwd = 0
let g:terminal_list = 0 " hide terminal in buffers list

call plug#end()

let $FZF_DEFAULT_OPTS="--preview-window 'right:57%' --preview 'bat --style=numbers --line-range :300 {}'
\ --bind ctrl-y:preview-up,ctrl-e:preview-down"

" keymap | general
" make saving easier
nnoremap <Leader>w :w<CR>
" this piece of trash needs to die
map Q <Nop>
" don't yank when pasting

inoremap <C-@> <C-x><C-o>
"make Y copy to the end of the line
nnoremap Y y$
" searching should keep the cursor in the same place
"nnoremap n nzt
"nnoremap N Nzt
" undo break points..don't undo every damn thing from last insert
inoremap , ,<c-g>u
inoremap = =<c-g>u
inoremap , ,<c-g>u
inoremap . .<c-g>u
"duplicate (copy) blocks of text
nnoremap <Leader>cb Va}:t'><CR>

" yank current word and paste into Ag
nnoremap <Leader>fl :G log -p --follow -- %<CR>
nnoremap <Leader>fg :G<CR>
" folding
nnoremap <Leader>rf vi{zF

nnoremap <Leader>rs :wa<CR>:mksession!<CR>:qa
" execute the test I'm in then jump back
nnoremap <Leader>cf m':call search("^func", "b")<cr>Wyiw<C-o>

" keymap | navigation
nnoremap <Leader>gv :exe 'AsyncRun -mode=term cd '.expand('%:p:h').' && go vet ./... && echo checks out'<CR>
nmap <C-k> :cprev<CR>
nmap <C-j> :cnext<CR>

" see current file changes master
nnoremap <Leader>cm :Gdiffsplit origin/master<CR>

" keymap | search
" search selected text on / in visual mode
vnoremap / <Esc>/\%V

" highlight extra whitespace
" keep this at the bottom
hi ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" stop indention "help"
filetype indent off
set noautoindent
set nocindent
set nosmartindent
set indentexpr=

" always scroll to the left
autocmd WinEnter * normal! 100zh

" remember line position
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

autocmd FileType go nnoremap <Leader>go :AsyncRun -mode=term go doc -all %:p:h<CR>

" navigate between functions
autocmd FileType go nnoremap ]] :call search("^func")<cr>zt
autocmd FileType go nnoremap [[ :call search("^func", "b")<cr>zt

" change cursorline on insert
set cursorline
autocmd InsertEnter * set nocursorline
autocmd InsertLeave * set cursorline

" better window naming
autocmd BufReadPost,FileReadPost,BufNewFile * call system("tmux rename-window " . expand("%"))

