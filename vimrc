set nocompatible
set nowrap
set number  " line numbers
set ignorecase " don't care about case in search
set smartcase
set hlsearch
set incsearch
set noswapfile
set title
" set showmatch " jump to matching bracket
set showcmd
set laststatus=2
set encoding=utf-8
set updatetime=100
set splitright
set timeoutlen=350 ttimeoutlen=0 " ms to wait before waiting for extra keys
set shortmess-=S " show count when searching
set shortmess+=c
set scrolloff=5
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
" set spell spelllang=en_us spelloptions=camel
" set so=999 " cursor always in center of screen

" allow backspace to delete indentation and inserted text
set backspace=indent,eol,start

" remap leader
let mapleader = "\<Space>"

" " ctrl-e and ctrl-y moves cursor too
" function! s:Saving_scroll(cmd)
"   let save_scroll = &scroll
"   execute 'normal! ' . a:cmd
"   let &scroll = save_scroll
" endfunction
" nnoremap <C-y> :call <SID>Saving_scroll("1<C-V><C-U>")<CR>
" nnoremap <C-e> :call <SID>Saving_scroll("1<C-V><C-D>")<CR>

" remember my buffers
exec 'set viminfo=%,' . &viminfo

" remember line position
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

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

" change cursorline on insert
set cursorline
autocmd InsertEnter * set nocursorline
autocmd InsertLeave * set cursorline

" system clipboard
set clipboard=unnamed
if system('uname -s') == 'Linux'
    set clipboard=unnamedplus
endif

" speed things up
set lazyredraw
set ttyfast

" tab spacing
autocmd FileType go setlocal tabstop=2
autocmd FileType go setlocal shiftwidth=2
autocmd FileType sh setlocal tabstop=2
autocmd FileType sh setlocal shiftwidth=2

" better window naming
autocmd BufReadPost,FileReadPost,BufNewFile * call system("tmux rename-window " . expand("%"))

" syntax highlighting
syntax on
filetype on
filetype plugin on

" nvim terminal
tnoremap <Esc> <C-\><C-n>

" treesitter setup - for lua
" use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }  -- Highlighting etc

" treesitter config - for lua
" require'nvim-treesitter.configs'.setup {
"   ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
"   -- ignore_install = { "javascript" }, -- List of parsers to ignore installing
"   highlight = {
"     enable = true,              -- false will disable the whole extension
"     -- disable = { "c", "rust" },  -- list of language that will be disabled
"   },
"   incremental_selection = {
"     enable = true,
"     keymaps = {
"       init_selection = "gnn",
"       node_incremental = "grn",
"       scope_incremental = "grc",
"       node_decremental = "grm",
"     },
"   },
" }

" plugins
call plug#begin('~/.vim/plugged')

Plug 'mhinz/vim-startify'
let g:startify_change_to_dir = 0
let g:startify_bookmarks = [ {'v': '~/.vimrc'}, {'z': '~/.zshrc'} ]
let g:startify_enable_special = 0
let g:startify_lists = [
  \ { 'type': 'dir',       'header': ['   MRU '. getcwd()] },
  \ { 'type': 'files',     'header': ['   MRU']            },
  \ { 'type': 'sessions',  'header': ['   Sessions']       },
  \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
  \ { 'type': 'commands',  'header': ['   Commands']       },
  \ ]

Plug 'liuchengxu/vim-which-key'
nnoremap <silent> <Leader> :WhichKey '<Space>'<CR>
vnoremap <silent> <Leader> :WhichKeyVisual '<Space>'<CR>

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
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

Plug 'majutsushi/tagbar'
let g:tagbar_width=120
let g:tagbar_position='topleft vertical'

Plug 'yuttie/comfortable-motion.vim'

" REMOVE AFTER A TIME
" Plug 'haya14busa/incsearch.vim'
" let g:incsearch#auto_nohlsearch = 1

Plug 'tpope/vim-commentary'
nnoremap <Leader>/ :Commentary<CR><Esc>
vnoremap <Leader>/ :Commentary<CR><Esc>

Plug 'machakann/vim-highlightedyank' "highlight what you yank

Plug 'tpope/vim-fugitive'
Plug 'shumphrey/fugitive-gitlab.vim' "use :GBrowse to open files in gitlab

Plug 'rafaelsq/nvim-goc.lua'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline#extensions#tabline#enabled = 1
let g:airline_section_b='' " don't display git stuff
let g:airline_section_y='' " don't display encoding
let g:airline_section_z='' " don't display file progress
let g:airline#extensions#hunks#enabled = 0
" don't display mode
let g:airline_mode_map = {
    \ '__'     : '',
    \ 'c'      : '',
    \ 'i'      : '',
    \ 'ic'     : '',
    \ 'ix'     : '',
    \ 'n'      : '',
    \ 'multi'  : '',
    \ 'ni'     : '',
    \ 'no'     : '',
    \ 'R'      : '',
    \ 'Rv'     : '',
    \ 's'      : '',
    \ 'S'      : '',
    \ ''     : '',
    \ 't'      : '',
    \ 'v'      : '',
    \ 'V'      : '',
    \ ''     : '',
    \ }
let g:airline_theme='xtermlight'
" let g:airline_theme='term'
" let g:airline_theme='luna'
" let g:airline_theme='base16_heetch'

Plug 'mbbill/undotree'

Plug 'scrooloose/nerdtree'
let g:NERDTreeWinSize=70
let NERDTreeQuitOnOpen=1
let NERDTreeShowLineNumbers=1

Plug 'SirVer/ultisnips'
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger='<c-j>'
let g:UltiSnipsJumpBackwardTrigger='<c-k>'
let g:UltiSnipsEditSplit='horizontal'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'

" debugging
" Plug 'puremourning/vimspector'
Plug 'mfussenegger/nvim-dap'
Plug 'leoluz/nvim-dap-go'
Plug 'rcarriga/nvim-dap-ui'
let g:dap_adapters = {'go': {'type': 'executable', 'command': 'dlv'}}
let g:dap_virtual_text = v:true
let g:dap_virtual_text_highlight = 'Comment'
let g:vimspector_session_initialization_timeout = 60000

" Set up the Go debugger
let g:dap_virtual_text = v:true
let g:dap_virtual_text_highlight = 'Comment'
let g:dap_debugger = 'go'
let g:dap_debugger_args = ['dap', '-l', '127.0.0.1:38697']
let g:dap_debugger_path = 'dlv'
let g:dap_debugger_log = v:true
let g:dap_debugger_port = 38697
let g:dap_virtual_text = v:true
let g:dap_virtual_text_highlight = 'Comment'

Plug 'jeetsukumaran/vim-buffergator'
let g:buffergator_suppress_keymaps = 1
let g:buffergator_sort_regime = "mru"
let g:buffergator_show_full_directory_path = 0
let g:buffergator_vsplit_size = 60
let g:buffergator_viewport_split_policy = "L"

Plug 'skywind3000/vim-terminal-help'
let g:terminal_key = "<c-h>"
let g:terminal_height = 25
let g:terminal_pos = "topleft"
let g:terminal_close = 1
let g:terminal_cwd = 0
let g:terminal_list = 0 " hide terminal in buffers list

Plug 'skywind3000/asyncrun.vim'

Plug 'szw/vim-maximizer'

Plug 'airblade/vim-gitgutter'
let g:gitgutter_map_keys = 0

" Plug 'tpope/vim-dadbod'
" let g:ts = 'postgresql://localhost:5432/external-timescale?user=speedscale&password=079d9b7096130966a090'
"Plug 'kristijanhusak/vim-dadbod-completion'

" colorscheme
set background=dark
" Plug 'ray-x/aurora'
set termguicolors
" == DARK ==
" colorscheme aetrora
" source ~/.vim/plugged/aurora/colors/aurora.vim
" colorscheme palenight
" Plug 'morhetz/gruvbox'
Plug 'ellisonleao/gruvbox.nvim'

Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
" seems to block copilot
" Plug 'hrsh7th/cmp-copilot'
Plug 'hrsh7th/cmp-nvim-lua'
" this broke my tab :(
" Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'glepnir/lspsaga.nvim', { 'branch': 'main' }

" requirement for several other plugins
Plug 'nvim-lua/plenary.nvim'

" view LSP symbols in fzf
Plug 'gfanto/fzf-lsp.nvim'

Plug 'junegunn/gv.vim'

Plug 'sindrets/diffview.nvim'

" Plug 'github/copilot.vim'

" free copilot alternative
Plug 'Exafunction/codeium.vim'

" GUI manager for LSP, DAP, linters, etc
Plug 'williamboman/mason.nvim'

" lsp for JAVA - also uses jdtls binary
" this plugin requires it be explicitly installed, at least in my tests
Plug 'mfussenegger/nvim-jdtls'

Plug 'sindrets/winshift.nvim'

" markdown previewer
Plug 'ellisonleao/glow.nvim'

call plug#end()

let $FZF_DEFAULT_OPTS="--preview-window 'right:57%' --preview 'bat --style=numbers --line-range :300 {}'
\ --bind ctrl-y:preview-up,ctrl-e:preview-down"

" keymap | general
" make saving easier
nnoremap <Leader>w :w<CR>
" this piece of trash needs to die
map Q <Nop>

" navigate between functions
autocmd FileType go nnoremap ]] :call search("^func")<cr>
autocmd FileType go nnoremap [[ :call search("^func", "b")<cr>

inoremap <C-@> <C-x><C-o>
nnoremap <Leader>O :only<CR>:noh<CR>
nnoremap <Leader>o :lclose<CR>:cclose<CR>:noh<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>Q :q!<CR>
nnoremap <Leader>p :Files<CR>
nnoremap <Leader>v <C-v>
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

nnoremap <Leader>h <C-W>h
nnoremap <Leader>j <C-W>j
nnoremap <Leader>k <C-W>k
nnoremap <Leader>l <C-W>l
nnoremap <Leader><Esc> <C-W><C-P>

" keymap | edit
nnoremap <Leader>ew :e %:p:h
nnoremap <Leader>es :sp %:p:h
nnoremap <Leader>ev :vsp %:p:h

" keymap | buffers
nnoremap <Leader>bn :bnext<CR>
nnoremap <Leader>bb :e#<CR>
nnoremap <Leader><Space> :e#<CR>
nnoremap <Leader>bd :bd<CR>
nnoremap <Leader>bD :bd!<CR>
nnoremap <Leader>bm :WinShift<CR>

" keymap | tabs
nnoremap <Leader>tn :tabnew<CR>
nnoremap <Leader>tf :tabfind
nnoremap <Leader>th :tabprev<CR>
nnoremap <Leader>tl :tabnext<CR>
nnoremap <Leader>tq :tabclose<CR>

" " keymap | location list
" disabled to use for CocNext
" nmap <C-j> :cnext<CR>zt
" nmap <C-k> :cprev<CR>zt

" keymap | focus
nnoremap <Leader>fn :NERDTreeFind<CR>
" only open windows
nnoremap <Leader>fw :Windows<CR>
" all buffers
nnoremap <Leader>ff :BuffergatorOpen<CR>
nnoremap <Leader>f/ :Buffers<CR>
nnoremap <Leader>ft :TagbarOpenAutoClose<CR>
nnoremap <Leader>fT :TagbarOpen<CR>
nnoremap <Leader>fm :MaximizerToggle!<CR>
nnoremap <Leader>fr :Startify<CR>
nnoremap <Leader>fa :Ag 
" yank current word and paste into Ag
nnoremap <Leader>fA yiw:Ag <C-r>"<CR>
nnoremap <Leader>fF :Ag FIXME: \(JMT\)<CR>
nnoremap <Leader>fb :Ag BOOKMARK:<CR>
nnoremap <Leader>fl :G log -p --follow -- %<CR>
nnoremap <Leader>fg :G<CR>
nnoremap <Leader>fB :Lines<CR>
" folding
nnoremap <Leader>rf vi{zF

" keymap | run
nnoremap <Leader>rr :wa<CR>:AsyncRun<Up><CR><Esc>
" nnoremap <Leader>rt :AsyncRun -mode=term source ~/.zshrc-lite && 
nnoremap <Leader>rt :AsyncRun -mode=term -pos=thelp 
nnoremap <Leader>rT :AsyncRun -mode=term source ~/.zshrc-lite && 
nnoremap <Leader>rj V:!jq<CR>
vnoremap <Leader>rj :!jq<CR>
" nnoremap <Leader>rf :%foldc<CR> " doesn't work without setting something like tabmethod=indent
nnoremap <buffer> <Leader>rc :lua vim.lsp.buf.code_action()<CR>
" nnoremap <Leader>ra :ALEReset<CR>
nnoremap <Leader>rs :wa<CR>:mksession!<CR>:qa

" keymap | resize
nmap <Leader>, :10winc<<CR>
nmap <Leader>< :35winc<<CR>
nmap <Leader>. :10winc><CR>
nmap <Leader>> :35winc><CR>
nmap <Leader>- :resize -15<CR>
nmap <Leader>+ :resize +15<CR>

" rust
autocmd FileType rs nnoremap <Leader>w :rustfmt %:w<CR>

" keymap | navigation
nnoremap <Leader>gv :exe 'AsyncRun -mode=term cd '.expand('%:p:h').' && go vet ./... && echo checks out'<CR>
nmap <C-k> :cprev<CR>
nmap <C-j> :cnext<CR>
" nnoremap <Leader>dd :call vimspector#Launch()<CR>

autocmd BufWritePre *.go lua OrgImports(1000)
autocmd BufWritePre *.go lua vim.lsp.buf.format()
" nnoremap <Leader>db :call vimspector#ToggleBreakpoint()<CR>
" nnoremap <Leader>d<space> :call vimspector#Continue()<CR>
" nnoremap <Leader>do :call vimspector#StepOut()<CR>
" nnoremap <Leader>dn :call vimspector#StepOver()<CR>
" nnoremap <Leader>di :call vimspector#StepInto()<CR>
" nnoremap <Leader>dh :call vimspector#RunToCursor()<CR>
" nnoremap <Leader>dq :call vimspector#Reset()<CR>
" nnoremap <Leader>dr :call vimspector#Restart()<CR>
" nmap <Leader>dI <Plug>VimspectorBalloonEval
" xmap <Leader>dI <Plug>VimspectorBalloonEval
" nmap <Leader>dc <Plug>VimspectorToggleConditionalBreakpoint


" keymap | git changes
nnoremap <Leader>cs :GitGutterStageHunk<CR>
nnoremap <Leader>cc :GitGutterNextHunk<CR>
nnoremap <Leader>cC :GitGutterPrevHunk<CR>
nnoremap <Leader>cd :Gvdiffsplit<CR>
nnoremap <Leader>co :Gvsplit<CR>
nnoremap <Leader>cu :GitGutterUndoHunk<CR>
" see current file changes master
nnoremap <Leader>cm :Gdiffsplit origin/master<CR>

" keymap | coc
" nnoremap <Leader>cr :CocListResume<CR>
" nnoremap <Leader>cn :CocNext<CR>
" nnoremap <Leader>cN :CocPrev<CR>

" macros
let @f="A // FIXME: (JMT) "
let @b="A // BOOKMARK: "
let @d="lBveyO// \<Esc>pA "

" tabs for go
autocmd FileType go setlocal noexpandtab

" highlight extra whitespace
" keep this at the bottom
hi ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

function! s:decoratedYank()
    redir @n | silent! :'<,'>number | redir END
    let filename=expand("%")
    let decoration=repeat('-', len(filename)+1)
    let @*=decoration . "\n" . filename . ':' . "\n" . decoration . "\n" . @n
endfunction

vn <C-y> :call <SID>decoratedYank()<CR>

" stop indention "help"
filetype indent off
set noautoindent
set nocindent
set nosmartindent
set indentexpr=

autocmd FileType go nnoremap <Leader>go :AsyncRun -mode=term go doc -all %:p:h<CR>
lua <<EOF
  function OrgImports(wait_ms)
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, wait_ms)
    for _, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit, "UTF-8")
        else
          vim.lsp.buf.execute_command(r.command)
        end
      end
    end
  end
EOF
