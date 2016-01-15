" Helpful links:
" http://amix.dk/vim/vimrc.html
" http://stackoverflow.com/questions/164847/what-is-in-your-vimrc
" https://github.com/mutewinter/dot_vim/blob/master/vimrc

set nocompatible

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Vundle: https://github.com/gmarik/vundle
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

filetype off
let $GIT_SSL_NO_VERIFY = 'true'

set runtimepath+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" other plugins
Plugin 'majutsushi/tagbar'
Plugin 'desert-warm-256'
"Plugin 'fholgado/minibufexpl.vim'
"Plugin 'SuperTab-continued.'
"Plugin 'YankRing.vim'
"Plugin 'ervandew/screen'
Plugin 'derekwyatt/vim-scala'
Plugin 'othree/html5.vim'
"Plugin 'gre/play2vim'
Plugin 'groenewege/vim-less'
Plugin 'hail2u/vim-css3-syntax'
Plugin 'gregsexton/gitv'
"Plugin 'msanders/snipmate'
"Plugin 'tpope/vim-fugitive'
"Plugin 'Lokaltog/vim-easymotion'
"Plugin 'L9'
"Plugin 'FuzzyFinder'
"Plugin 'git://git.wincent.com/command-t.git' 
Plugin 'tfnico/vim-gradle'
"Plugin 'jngeist/vim-multimarkdown'
"Plugin 'vim-pandoc/vim-pantondoc'
"Plugin 'vim-pandoc/vim-pandoc-syntax'
Plugin 'ekalinin/Dockerfile.vim'

" end plugins
call vundle#end()

let g:yankring_history_dir = '~/.vim'
let g:yankring_history_file = 'yankring_history'

filetype plugin indent on

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" History
set history=100
set viminfo+=n~/.vim/viminfo

" Colors
syntax on
colorscheme desert-warm-256

" Status line
set ruler
set showmode
set laststatus=2

" Completion
set wildmenu
set wildmode=list:longest
set wildignore=*.o,*.obj,*.bak,*.bk,*~

" Editing
set completeopt=menu,longest,preview
set backspace=eol,start,indent
set whichwrap+=<,>,h,l
" set formatoptions+=tcrql

" Cut & paste
set pastetoggle=<F2>

" Use Q for formatting the current paragraph (or selection)
vmap Q gq
nmap Q gqap

" Search
set smartcase
set hlsearch
set incsearch
set matchtime=5

" Brackets
set showmatch

" No sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Tabs and spaces
set smarttab
set expandtab
set softtabstop=4
set tabstop=4 
set listchars=tab:>-,trail:-

" Indents
set autoindent
set smartindent
set shiftwidth=4
set shiftround
set copyindent
set preserveindent

" Folds
"set foldcolumn=2
"set foldmethod=indent

" Allow command mode w/o shift
nore ; :
nore , ;

" Cursor
set scrolloff=1
set sidescrolloff=15
set sidescroll=1
set whichwrap+=b,s,<,>,[,]

" Text wrapping
set textwidth=100
set nowrap

" Swap files must die
if has("win32") || has("win64")
    set backupdir=$TMP
    set directory=$TMP
else
    set backupdir=~/backup,~/backups,/var/tmp,/tmp
    set directory=~/backup,~/backups,/var/tmp,/tmp
end 

" Misc
set nobackup
set shell=zsh
set virtualedit=block
set lazyredraw

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Key Mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Allow Alt/Meta modifiers
set winaltkeys=no

" Window navigation
map <m-left> <c-w><left>
map <m-up> <c-w><up>
map <m-down> <c-w><down>
map <m-right> <c-w><right>

" Window movement
map <m-s-left> <c-w>H
map <m-s-down> <c-w>J
map <m-s-up> <c-w>K
map <m-s-right> <c-w>L

" Window resizing
map <m-,> <c-w><
map <m-down> <c-w>-
map <m-up> <c-w>+
map <m-.> <c-w>>
map <m-=> <c-w>=

" Buffer switching
map <C-j> :bprev<CR>
map <C-k> :bnext<CR>
set hidden

" Mintty application escape mode
"let &t_ti.="\e[?7727h"
"let &t_te.="\e[?7727l"
"noremap <Esc>O[ <Esc>
"noremap! <Esc>O[ <Esc> " vi default
"noremap! <Esc>O[ <C-c> " vim default

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:pandoc_use_conceal = 0

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => File types
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

autocmd FileType vim setlocal expandtab shiftwidth=4 tabstop=8 softtabstop=4
autocmd FileType sh setlocal expandtab shiftwidth=4 tabstop=8 softtabstop=4
autocmd FileType ruby,scala setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType html,xhtml,xml setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType css setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType javascript setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2
let javascript_enable_domhtmlcss=1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Encodings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" See http://vim.wikia.com/wiki/Working_with_Unicode#References
if has("multi_byte")
  set encoding=utf-8
  setglobal fileencoding=utf-8
  "setglobal bomb
  set fileencodings=ucs-bom,utf-8,latin1
endif
