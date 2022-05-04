#!/bin/bash
#d#




#d#==head2 blocksize $dev
#d# @category : disk
#d#
#d# show size in mbyte and gbyte of device.
#d#
function blocksize() {
  local BLOCKDEV=$1
  BLOCKDEV_SIZE=$(blockdev --getsize64 $BLOCKDEV)
  echo byte : $BLOCKDEV_SIZE
  echo mbyte: $(($BLOCKDEV_SIZE / 1024 / 1024))
  echo gbyte: $(($BLOCKDEV_SIZE / 1024 / 1024 / 1024))
}

#d#==head2 pvc : copy one disk to another
#d# @category : disk
#d#
#d# @param1: source dev
#d# @param2: dest. dev
#d#
function copydiskpv() {
  if ! which pv; then
    echo "you need pv: yum install pv; apt-get install pv;"
    return 1
  fi
  if [ ! -b "$1" ]; then echo "$1 is not a blockdevice"; return; fi
  if [ ! -b "$2" ]; then echo "$2 is not a blockdevice"; return; fi
  blkid $1
  blkid $2
  echo "are you sure?"; read -n 1
  local bs="64k"
  dd if=$source bs=$bs |pv -s $(blockdev --getsize64 $source) | dd of=$dest bs=$bs
}

#d#==head2 ddsig : sends signal to dd
#d# @category : disk
#d#
#d# sends signal to dd
#d#
function ddsig() {
  COUNTER=$1
  if [ "$1" == "" ]; then
    COUNTER=1
  fi
  for (( COUNT=1; COUNT <= $COUNTER; COUNT++ )); do
    DDPID=$(ps aux |grep "dd [io]f" |awk '{ print $2 }'); kill -USR1 $DDPID
    if [ "$COUNT" != $COUNTER ]; then sleep 30s; fi
  done
}



