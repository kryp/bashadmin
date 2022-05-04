#!/bin/bash                                                                                                                                                                                                      #d#
#d#
#d#
#d#
#d#


IMAGEDIR=/mnt/images
IMGDIR=/home/imagestemplates
STAGE=puppet
LVM="dellt20-vg"
TARGET="d10-playstation-3"
#LVM=vg-01

OS="debian"; VER="10"

function multimage() {
  LIST="$1"
  #ITEMS=$(ls /dev/mapper/*$LIST*)
  ITEMS=$(ls /dev/mapper/ |grep "$LIST.*[^0123456789]$")
  echo "$ITEMS"
}

function imagecopy() {
  DEV=/dev/mapper/$1
  IMAGE=ubuntu.20.04.puppet.dd
  dd bs=64k if=$IMGDIR/$IMAGE of=$DEV
# qemu-img convert -f qcow2 -O raw ubuntu.20.04.puppet.dd.qcow /dev/mapper/vg01-imgdebian.test.dholz.try2.net
}

function imagecreate() {
  DEV=/dev/mapper/$1
  IMAGE=$2
  qemu-img convert -f raw -O qcow2 $DEV $IMGDIR/$IMAGE.qcow
}

function imageinfo() {
  DEV=/dev/mapper/$1
  tuneinfo $DEV |grep "Block count"
  # Inode / Block * 4096
}

function imageresize() {
  DEV=/dev/mapper/$1
  #/dev/mapper/vg01-database1.test.dholz.try2.net1
  parted $DEV resizepart 1 100% || return $?
  kpartx -a $DEV
  DEVPART=${DEV}1
  e2fsck -f $DEVPART
  resize2fs $DEVPART
  kpartx -d $DEV
}

function imagedeploy() {
  OS=$1
  VMDEV=$2
  if [ "$OS" == "debian" ]; then
    IMG="debian.10.puppet"
  elif [ "$OS" == "ubuntu" ]; then
    IMG="ubuntu.20.04.puppet.dd"
  elif [ "$OS" == "centos" ]; then
    IMG="centos.7.puppet"
  else
    echo "unsupported os: $OS"
    return 1
  fi
  if [ "$2" == "" ]; then
    echo "imagedeploy \$img \$vm"
    return 1
  else
    if [ ! -r "$IMGDIR/$IMG.qcow" ]; then
      echo "could not find $IMGDIR/$IMG.qcow"
    else
      echo "copying $IMGDIR/$IMG.qcow /dev/mapper/$VMDEV"
      qemu-img convert -f qcow2 -O raw $IMGDIR/$IMG.qcow /dev/mapper/$VMDEV | return 1
      #dd bs=64k if=$IMAGEDIR/$IMGNAME of=/dev/$LVM/$TARGET
      imageresize $VMDEV
    fi
  fi
}


function imagedeployfull() {
  #IMG=$1
  OS=$1
  VER=$2
  DEST=$3
  TARGET=$4
  if [ "$2" = ""]; then
    echo "imagedeploy \$img \$dst"
  else
    #IMGNAME="${IMG}.dd"
    IMGNAME="${OS}.${VER}.${STAGE}.dd"
    TARGET_LVM=$(echo "$LVM" |sed 's/-/--/g')
    TARGET_NAME=$(echo "$TARGET" |sed 's/-/--/g')
    TARGETNAME="${TARGET_LVM}-${TARGET_NAME}"
    ls -l /dev/mapper/${TARGETNAME}p1

    ls -l $IMAGEDIR/$IMGNAME
    if [ ! -r $IMAGEDIR/$IMGNAME ]; then
      echo "could not find $IMAGEDIR/$IMGNAME"
    else
      dd bs=64k if=$IMAGEDIR/$IMGNAME of=/dev/$LVM/$TARGET

      parted /dev/$LVM/$TARGET resizepart 1 100%
      kpartx -a /dev/$LVM/$TARGET
      e2fsck -f /dev/mapper/${TARGETNAME}p1
      resize2fs /dev/mapper/${TARGETNAME}p1
      kpartx -d /dev/$LVM/$TARGET
    fi
  fi
}

