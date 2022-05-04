#!/bin/bash
#d#
#d#
#d# https://opensource.com/article/20/2/how-install-vim-plugins
#d#
##################################################################


function vimpata() {
#    if [ ! -L ~/.vim ]; then
#      ln -fs $EENV_SCRIPTDIR/contrib/vim ~/.vim || return 1
#    fi
    if [ ! -r ~/.vim/autoload/pathogen.vim ]; then
      kwget ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim || return 1
    fi
    if ! grep "execute pathogen" ~/.vimrc 2>&1 >/dev/null; then
      echo 'execute pathogen#infect()' >>~/.vimrc
    fi
}

#d#==head2 vimrc
#d#
function vimrc() {
  if [ ! -d $HOME/.vim/autoload ]; then mkdir -p $HOME/.vim/autoload; fi
  if [ ! -d $HOME/.vim/bundle ]; then mkdir -p $HOME/.vim/bundle; fi
  cat >~/.vimrc<<'EOF'
" kryp rc.2 installed with profile-start.sh
set tabstop=2
set expandtab
set shiftwidth=2
set noautoindent
set laststatus=2                " always show filename/status bar
"set ruler                       " show row/column number in status bar
set scrolloff=4                 " always show 3 lines above or below cursor
set title                       " change title of xterm window
set history=150                 " keep 50 lines of command line history
set visualbell                  " Blink cursor on error instead of beeping
set noerrorbells                " No annoying sound on errors
set ttyfast                     " rendering
set encoding=utf8               " Set utf8 as standard encoding and en_US as the standard language

syntax on
hi Comment ctermfg=cyan

" *** shortcuts ***
"ab [+ [+ +]<left><><left>
" html-commands
"ab <!-- ><left><left>
" perl dump
"ab print Data::Dumper::Dumper ( print Data::Dumper::Dumper ();die;<left><left><left><left><left><left>
" perl long-die
ab perldie die(Carp::longmess(__FILE__." failed on line: ".__LINE__)); die(Carp::longmess(__FILE__." failed on line: ".__LINE__));

" *** key-mappings ***
"
map <F2> :w!<CR>:! ./%<CR>
" PERL show sub
map <F3> :! grep -n "^sub " ]] <CR>
command Json :%!/usr/bin/python3 -m json.tool<CR>
map <F4> :%!python -m json.tool<CR>
" map <F4> @w
"
map <F6> bvEy:sp ./[[<CR>
" C compile and run code
map <F8> :w!<CR>:! rm a.out<CR>:! cc ]]<CR>:! ./a.out<CR>

set cursorline          " highlight current line
set lbr
set tw=500 " Linebreak on 500 characters
set wildmenu                      " Better command-line completion

" Bubble single lines
nmap <C-Up> ddkP
nmap <C-Down> ddp


" *** info ***
" set nocompatible
" convert
" set fileformat=unix);die;

" modeline to detect vim-settings in file
set modeline
" set expandtab
" set autoindent
" set smartindent

set notitle

" remove trailing whitespace
autocmd BufWritePre * %s/\s\+$//e


EOF

  # seealso kdesktop
  if [ "$PROFILE_DOMAIN" == "kryp" ]; then
#    if [ ! -L ~/.vim ]; then
#      ln -fs $EENV_SCRIPTDIR/contrib/vim ~/.vim || return 1
#    fi
    if [ ! -r ~/.vim/autoload/pathogen.vim ]; then
      kwget ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim || return 1
    fi
    if ! grep "execute pathogen" ~/.vimrc 2>&1 >/dev/null; then
      echo 'execute pathogen#infect()' >>~/.vimrc
    fi
  elif [ "$PROFILE_DOMAIN" == "fdsg" ]; then
    :
  else
    if [ ! -d ~/.vim/autoload ]; then
      mkdir -p ~/.vim/autoload ~/.vim/bundle
    fi
    if [ ! -r ~/.vim/autoload/pathogen.vim ]; then
      kwget ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim || return 1
    fi
    if ! grep "execute pathogen" ~/.vimrc 2>&1 >/dev/null; then
      echo 'execute pathogen#infect()' >>~/.vimrc
    fi
    cd ~/.vim/bundle
  fi
}


