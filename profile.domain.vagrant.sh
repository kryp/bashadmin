#!/bin/bash
#d#


#d#==head2 vagrant()
#d#
#d# seealso: puppetinstall
#d# install vagrant & tools (could be done by kvagrant)
#d# checkout kvagrant (or add to kpuppet)
#d# install.sh (in kvagrant)
#d#
alias vags="vagrant global-status"
alias vagsg="vagrant global-status | grep "
alias vagdo="vagrant -f destroy; vagrant up; vagrant ssh"
alias vagus="vagrant up; vagrant ssh"
alias vagups="vagrant up; vagrant ssh"
alias vag="vagranttool"
function vagranttool() {
  echo "vagrant"
  if [ "$PROFILE_DOMAIN" == "test" ]; then
    :
  elif [ "$PROFILE_DOMAIN" == "kryp" ]; then
    ksshgitkey
    if [ ! /usr/bin/git ]; then
      kinst git
    fi
    if [ ! -d /opt/kvagrant ]; then
      git clone ssh://gitolite@itosdev.it-operation.de/kvagrant /opt/kvagrant
    fi
  fi
  vagrant "$@"
}



