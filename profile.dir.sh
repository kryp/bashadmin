#!/bin/bash
################################################################################################ _SEC: DIR
################################################################################################
#d#==head1 DIR
#d#
#d# seealso: ecd in desktop
#d#


function rootdirs() {
  (for i in $(ls /|grep -v proc); do
    if [ ! -d /$i ]; then continue; fi
    if [ "$(stat --printf=%m /$i)" != "/" ]; then continue; fi
    du -s /$i;
  done)|sort -n
}

#. /usr/share/autojump/autojump.sh

alias cdd="cd -"
alias dirroot='rootdirs'
#CDPATH=".:~"

