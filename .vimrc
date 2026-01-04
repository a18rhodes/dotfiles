" dotfiles/.vimrc

" --- The Basics ---
syntax on               " Enable syntax highlighting
set number              " Show line numbers
set ruler               " Show cursor position (row, col)
set clipboard=unnamed   " Use system clipboard (copy/paste works outside vim)

" --- Indentation ---
set smartindent         " Smart autoindenting on new lines
set autoindent          " Copy indent from current line when starting new one
set tabstop=4           " Tab width is 4 spaces
set shiftwidth=4        " Indent width is 4 spaces
set expandtab           " Use spaces instead of tabs (Python standard)

" --- Search ---
set ignorecase          " Case insensitive search
set smartcase           " ...unless query has uppercase letters
set incsearch           " Highlight matches as you type
set hlsearch            " Highlight all search matches

" --- User Mappings ---

" Map 'q' to quit.
" WARNING: This disables macro recording (q).
nnoremap q :q<CR>

" Map 'Q' to force quit (discard changes)
nnoremap Q :q!<CR>

" Map 'W' to save (write)
nnoremap W :w<CR>

" Make Y copy to end of line (like D or C)
nnoremap Y y$

" --- Visuals ---
set termguicolors       " True color support
colorscheme default     " You can change this later if you install themes
