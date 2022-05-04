#!/bin/bash
#d#
#d#
#d#
#d#

PV_COMMAND=$(which pv)
#if [ "$PV_COMMAND" == "" ]; then PROFILE_ERROR="pv;$PROFILE_ERROR"; fi

#d#==head2 copypv :
#d# @category : disk, copy
#d#
function copypv() {
  sourceDirectory=$1
  if [ "$PV_COMMAND" == "" ]; then
    echo "pv missing"
    return 1
  fi
  if [ "$sourceDirectory" == "" ]; then
    echo "copypv source [ target = . ]"
    return 1
  fi
  destinationDirectory=$2
  if [ "$destinationDirectory" == "" ]; then
    destinationDirectory="."
  fi
  tar c $sourceDirectory | pv | tar x -C $destinationDirectory

}

