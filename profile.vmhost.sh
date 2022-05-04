#!/bin/bash
#d#
#d#
#d#
#d#

PV_COMMAND=$(which virsh)
#if [ "$PV_COMMAND" == "" ]; then PROFILE_ERROR="virsh;$PROFILE_ERROR"; fi

#PROFILE_ERROR="error"

function vagrep() {
  virsh list --all |grep $1
}

#d#==head2 copypv :
#d# @category : disk, copy
#d#
function vstartall() {
  for i in $(virsh list --name --all); do virsh start $i; done
}
function vmshutdownall() {
  for i in $(virsh list --name); do virsh shutdown $i; done
}


