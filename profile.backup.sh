#!/bin/bash
#d#

#d#==head2 backup / restore
#d# @category : disk
#d#
#d# PROFILE_BACKUPHOST
#d#
function backup() {
  ssh root@${PROFILE_BACKUPHOST} "backup $@"
}
function restore() {
  ssh root@${PROFILE_BACKUPHOST} "restore $@"
}
