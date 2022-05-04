#!/bin/bash
#d#
#d#
#d#
#d#

function diskhelp() {
  cat <<EndOfHelp
diskl      : disk-list (Physical,Virtual)
diski      : info for a single disk (runs several other disk* tools)
disklock   : check why dev is locked (dosnt work :( )                                                                                                                                                            diskata    : old stolen script
diskpart   : show list of partitions for a volume and there type
diskhealth : show disk health
disktest   : test with badbocks or other tools for bad-sectors and other errors
             d(ryrun) t(est) f(force) (w)ritemode (b)adblocks (s)martctr";
diskserial : get serial no
EndOfHelp
}

#d#==head2 diskl :
#d# @category : disk
#d#
function diskl() {
  local list=$(cd /sys/block; ls);
# first list physical
  for item in $list; do
    if [ ! -b /dev/$item ]; then
      >2& echo "/dev/$item not found for /sys/block/$item";
      continue
    fi
    local device_link=$(readlink /sys/block/$item);
    if [[ "$device_link" =~ virtual ]]; then continue; fi
    if [[ "$item" =~ ^sr ]]; then continue; fi ###sr
    diskl_helper $item
  done
# list all others
  for item in $list; do
    local device_link=$(readlink /sys/block/$item);
    if [[ "$device_link" =~ pci ]]; then continue; fi
    if [[ "$item" =~ ^loop ]]; then continue; fi
    if [[ "$item" =~ ^ram ]]; then continue; fi

    diskl_helper $item
  done
}

function diskl_helper() {
  local item=$1;
  local device;
  local serial;
  local size;
  local device_link=$(readlink /sys/block/$item);
  # serial=$($BACKUP_SUDO  /sbin/udevadm info -q env -p /block/$devname |grep -i SERIAL_SHORT |cut -b 17-) ||
  if [[ "$item" =~ ^sd ]]; then
    serial=$(diskserial $item);
    device=${device_link:24:10};
  elif [[ "$item" =~ ^nvme ]]; then
    serial=$(nvme id-ctrl /dev/$item |grep "^sn" |cut -b 11-);
    device=${device_link:24:10};
  elif [[ "$item" =~ ^dm ]]; then
    serial=$(cat /sys/block/$item/dm/name);
    device=$(diskl_dmdevice $item);
  else
    serial="";
    device="dm"
  fi
  local uuid;
  local uuiddev;
  for uuiddev in $(ls /dev/disk/by-uuid/); do
    local devname=$(readlink /dev/disk/by-uuid/$uuiddev);
    #echo "($devname"
    devname=${devname##*/}
    if [ "$devname" == "$item" ]; then
      uuid=$uuiddev
    fi
  done
  local BLOCKDEV_SIZE;
  BLOCKDEV_SIZE=$(blockdev --getsize64 /dev/$item 2>&1);
  if [ $? == 0 ]; then
    size=$(($BLOCKDEV_SIZE / 1024 / 1024 / 1024));
  else
    size="-1";
    #size="$BLOCKDEV_SIZE";
  fi
  printf "%10s :%25s :%7s GB :%10s : %s" "$item" "$serial" "$size" "$device" "$uuid";
  echo;
}

function diskl_dmdevice() {
  local item=$1
  deps=$(dmsetup deps /dev/$item);
  echo $deps;                                                                                                                                                                                                    }




#d# @category : disk
#d#
function dinfo() {
  echo "* info : dinfo() : mount"
  mount  |grep -v "^none" |grep -v "^proc" |grep -v "^fusectl" |grep -v "binfmt_misc" |grep -v "^gvfs-fuse-daemon"

# /
  echo "* info : /"
  #DIRLIST=$(ls -1 / |grep -v "^dev"|grep -v "^boot" |grep -v "^bin" |grep -v "^sbin" |grep -v "^etc" |grep -v "^lib" |grep -v "^home" |grep -v "^mnt" |grep -v "^opt" |grep -v "^proc" |grep -v "^root" |grep - v "^usr" |grep -v "^var" |grep -v "^tmp" |grep -v "^media"  |grep -v "^lost" |grep -v "^sys" |grep -v "^selinux"
  ROOTSKIP=" boot bin sbin etc lib home mnt opt proc root usr var tmp media lost+found sys selinux"
  ROOT_LS=$(ls /)
  dinfo-skip "$ROOT_LS" "$ROOTSKIP"

# /root
  echo "* info : /root"
  DU_ROOT=$(du -hs /root)
  echo "/root : ${DU_ROOT} : "
# /home
  echo "* info : /home"
  DU_HOME=$(du -hs /home 2>/dev/null| awk '{ print $1 }' )                                                                                                                                                         WC_HOME=$(ls /home|wc -l)
  echo "/home : ${DU_HOME} : ${WC_HOME}"

# /srv
  if [ -d /srv ]; then
    echo "* info /srv"
    du -hs /srv
  fi

# /var
  echo "* info /var"
  DU_VAR=$(du -hs /var)
  WC_VAR=$(ls /var|wc -l)
  echo "/var : ${DU_VAR} : ${WC_VAR}"
  VARSKIP="log tmp run mail spool opt cache crash games local lock mail"
  VAR_LS=$(ls /var)
  dinfo-skip "$VAR_LS" "$VARSKIP"

# /var/lib
  echo "* info /var/lib"
  DU_VARLIB=$(du -hs /var/lib)
  WC_VARLIB=$(ls /var/lib|wc -l)
  echo "/home : ${DU_VARLIB} : ${WC_VARLIB}"
  VARLIBSKIP="apt aptitude dpkg"
  VARLIB_LS=$(ls /var/lib)
  dinfo-skip "$VARLIB_LS" "$VARLIBSKIP"
}


function dinfo-skip() {
  VARLIST=$1
  VARSKIP=$2
  for I in $VARLIST; do
    for SKIP in $VARSKIP; do
      if [ "$I" == "$SKIP" ]; then
        continue 2
      fi
    done
    echo -n "$I "
  done
  echo
}

#d#==head2 dinfo : data overview
#d# @category : disk
#d#
function dinfo() {
	echo "* info : dinfo() : mount"
	mount  |grep -v "^none" |grep -v "^proc" |grep -v "^fusectl" |grep -v "binfmt_misc" |grep -v "^gvfs-fuse-daemon"

# /
	echo "* info : /"
	#DIRLIST=$(ls -1 / |grep -v "^dev"|grep -v "^boot" |grep -v "^bin" |grep -v "^sbin" |grep -v "^etc" |grep -v "^lib" |grep -v "^home" |grep -v "^mnt" |grep -v "^opt" |grep -v "^proc" |grep -v "^root" |grep -v "^usr" |grep -v "^var" |grep -v "^tmp" |grep -v "^media"  |grep -v "^lost" |grep -v "^sys" |grep -v "^selinux"
	ROOTSKIP=" boot bin sbin etc lib home mnt opt proc root usr var tmp media lost+found sys selinux"
	ROOT_LS=$(ls /)
	dinfo-skip "$ROOT_LS" "$ROOTSKIP"

# /root
	echo "* info : /root"
	DU_ROOT=$(du -hs /root)
	echo "/root : ${DU_ROOT} : "
# /home
	echo "* info : /home"
	DU_HOME=$(du -hs /home 2>/dev/null| awk '{ print $1 }' )
	WC_HOME=$(ls /home|wc -l)
	echo "/home : ${DU_HOME} : ${WC_HOME}"

# /srv
	if [ -d /srv ]; then
		echo "* info /srv"
		du -hs /srv
	fi

# /var
	echo "* info /var"
	DU_VAR=$(du -hs /var)
	WC_VAR=$(ls /var|wc -l)
	echo "/var : ${DU_VAR} : ${WC_VAR}"
	VARSKIP="log tmp run mail spool opt cache crash games local lock mail"
	VAR_LS=$(ls /var)
	dinfo-skip "$VAR_LS" "$VARSKIP"

# /var/lib
	echo "* info /var/lib"
	DU_VARLIB=$(du -hs /var/lib)
	WC_VARLIB=$(ls /var/lib|wc -l)
	echo "/home : ${DU_VARLIB} : ${WC_VARLIB}"
	VARLIBSKIP="apt aptitude dpkg"
	VARLIB_LS=$(ls /var/lib)
	dinfo-skip "$VARLIB_LS" "$VARLIBSKIP"
}


#d#==head2 diskata :
#d# @category : disk
#d#
function diskata() {
  # note: inspired by Peter
  # *UPDATE 1* now we're no longer parsing ls output
  # *UPDATE 2* now we're using an array instead of the <<< operator, which on its
  # part insists on a writable /tmp directory:
  # restricted environments with read-only access often won't allow you that
  # save original IFS
  OLDIFS="$IFS"
  for i in /sys/block/sd*; do
   readlink $i |
   sed 's^\.\./devices^/sys/devices^ ;
        s^/host[0-9]\{1,2\}/target^ ^ ;
        s^/[0-9]\{1,2\}\(:[0-9]\)\{3\}/block/^ ^' \
   \
    |
    while IFS=' ' read Path HostFull ID
    do
       # OLD line: left in for reasons of readability
       # IFS=: read HostMain HostMid HostSub <<< "$HostFull"
       # NEW lines: will now also work without a hitch on r/o environments
       IFS=: h=($HostFull)
       HostMain=${h[0]}; HostMid=${h[1]}; HostSub=${h[2]}

       if echo $Path | grep -q '/usb[0-9]*/'; then
         :
         echo "(Device $ID is not an ATA device, but a USB device [e. g. a pen drive])"
       else
         if [ -z "$1" ]; then
           echo $ID:ata$(< "$Path/host$HostMain/scsi_host/host$HostMain/unique_id").$HostMid$HostSub
         elif [ "$1" == "$ID" ]; then
           echo ata$(< "$Path/host$HostMain/scsi_host/host$HostMain/unique_id").$HostMid$HostSub
         fi
       fi
    done
  done
  # restore original IFS
  IFS="$OLDIFS"
}

################################################################################################ DISABLED
################################################################################################
if false; then
#d#==head2 __disklistpart() : list partitions
#d#
#d#
function __disklistpart() {
  local dev kpartx_l
  for dev in $(__disklist); do
    local devname=${dev##*/};
    local majorminor=$(cat /sys/block/$devname/dev);
    local devdmname=$(dmsetup ls|grep "($majorminor)" |awk '{ print $1 }');
    #if [ "${devdmname: -2:1}" == "p" ]; then continue; fi # could be a partition
    if [[ "${devdmname}" =~ p[0-9]*$ ]]; then continue; fi # could be a partition
    #echo "(dev=$dev)(majorminor=$majorminor)(dmname=$dmname) ${dmname: -2:1}";

    if [ "$1" == "add" ]; then
      kpartx_l="$(kpartx -a $dev 2>/dev/null)"; #  more complicated, cause should update __diskdb
    else
      kpartx_l="$(kpartx -l $dev 2>/dev/null)";
    fi
    if [ "$?" != 0 ]; then
      >&2 echo "$dev failed";
    elif [ ! -z "$kpartx_l" ]; then
      while read dmname colon startingzero size parentdev starting_block; do # (block 0 of loop0p1 is block 2048 of loop0)
        #echo "$dmname $colon $startingzero $size $parentdev $starting_block"
        if [[ $dev =~ dm- ]]; then
          echo "/dev/mapper/$dmname"; # ($dev) ($majorminor)";
        else
          echo "/dev/$dmname"; # ($dev) ($majorminor)";
        fi
      done <<<"$kpartx_l";
    else
      echo "$dev";
    fi
    if [ "$1" == "del" ]; then
      kpartx_l=$(kpartx -d $dev 2>&1)
      if [ "$?" =! 0 ]; then
        echo "$kpartx_l";
      fi
    fi
  done
}

#d#==head2 __diskdevlist : creates several hashes with disk-names
#d#
#d# /dev/dm-7
#d# ( /dev/testhost-vg/playstation-disk )
#d# /dev/mapper/testhost--vg-playstation--disk
#d# /dev/disk/by-uuid/f7ae7c19-7ded-4a06-b848-586752331501
#d# /dev/disk/by-id/dm-uuid-LVM-yyQniJGkswsG5hbnUyrBoThJeEgcUWe1D2afsRO4AHIgGtnn7uAUPftbrH6JCOIq
#d# /dev/disk/by-id/dm-name-testhost--vg-playstation--disk
#d# /dev/block/254:7
#d#
#d#

declare -A __diskdev __diskdevmapper __diskdevuuid __diskdevid __diskdevblock
function __diskdevlist() {
  if [ "${#__diskdev[*]}" -gt 0 ]; then
    return;
  fi
  #echo "${#__diskdevmapper[*]}";
  #for dev in $(cd /sys/block; ls); do
  #for dev in $(find . -type l); do

  for dev in $(find /dev/sd? /dev/mapper/ /dev/disk/ /dev/block/ -type l); do
    link=$(readlink $dev);
    if [ "$?" == 0 ]; then
      #echo "($dev)($link)";
      devname=${link##*/};
      if [ "${dev[@]:0:12}" == "/dev/mapper/" ]; then
        __diskdevmapper[$devname]="$dev";
      elif [ "${dev[@]:0:18}" == "/dev/disk/by-uuid/" ]; then
        __diskdevuuid[$devname]="$dev";
      elif [ "${dev[@]:0:16}" == "/dev/disk/by-id/" ]; then
        __diskdevid[$devname]="$dev";
      elif [ "${dev[@]:0:22}" == "/dev/disk/by-partlabel" ]; then
        __diskdevlabel[$devname]="$dev";
      elif [ "${dev[@]:0:10}" == "/dev/block" ]; then
        __diskdevblock[$devname]="$dev";
      else
        __diskdev[$devname]="$dev";
      fi
    else
      echo "not found ($dev)";
    fi
  done
  local i;
  if false; then
    for i in "${!__diskdev[@]}"; do  echo "key  : $i    __diskdev: ${__diskdev[$i]}"; done;
    for i in "${!__diskdevmapper[@]}"; do echo "key  : $i    __diskdevmapper: ${__diskdevmapper[$i]}"; done;
    for i in "${!__diskdevuuid[@]}"; do echo "key  : $i    __diskdevuuid: ${__diskdevuuid[$i]}"; done;
  fi
}

fi

#d#==head2 _get_diskdev ( $dev-str ) : check if /dev needs to be added and other checks
#d#
function _get_diskdev() {
  dev=""
  if [ -b $1 ]; then
      dev=$1
  else
    if [ -b /dev/$1 ]; then
      dev=/dev/$1
    else
      echo "could not find dev $1";
      return 1;
    fi
  fi
  if [ ! -r /sys/block/$devname ]; then
    >&2 echo "STRANGE: /sys/block/$devname not found"; return 1;
  fi
  return 0;
}

#d#==head2 diski $dev : info for diskserial diskhealth blocksize blkid diskpart
#d#
function diski() {
  if [ -z $1 ]; then
    echo "which dev?"
    return 1;
  fi
  _get_diskdev $1
  diskserial $dev
  diskhealth $dev
  blocksize $dev
  blkid $dev
  diskpart $dev
}


#d#==head2 disklock $1 : check why dev is locked
#d#
function disklock() {
  dev=$1
  # lsof
  # fuser
  # ../devices/virtual/block/md0/holders (md0)

  # lvm
  dmsetup=$(dmsetup info $dev 2>/dev/null) || false;
  if [ "$?" == 0 ]; then
    echo "($dmsetup)";
  else
    echo "no lvm";
  fi
  #if dmsetup info $dev; then
  # drbd : the only way is to check all drbd-drives
  #device=$(drbdsetup show all |grep -o "/dev[a-Z/0-9-]*");
  drbd_devices=$(drbdsetup show all |grep "disk.*\"" |awk '{ print $2 '} |sed 's/^"\(.*\)";/\1/')
  for item in $drbd_devices; do
    if [ "$dev" == "$item" ]; then
      echo "* DRBD LOCK"
    fi
  done

}

#d#==head2 diskpart $1 : show list of partitions for a volume and there type
#d#
#d# with different tools, if aviable
#d#
#d# output needed is just $dev : $size
#d#
#d# kpartx -l /dev/test
#d# parted /dev/test  print -m
#d# fdisk -l
#d#
#d# maybe can switch on/off kpartx
#d#
function diskpart() {
  local dev=$1
  if [ ! -b $dev ]; then
    echo "failed"; return 1;
  fi
  #if [ -x /sbin/kpartx ]; then /sbin/kpartx -l $kpartx_list fi

  local kpartx_list=$(kpartx -l $dev)
  if [ "$?" != 0 ]; then
    >&2 echo "$dev failed";
  elif [ ! -z "$kpartx_list" ]; then
    while read partition_name colon null size source_dev start_sector; do
      if [ -b /dev/mapper/$partition_name ]; then
        partition_dev="/dev/mapper/$partition_name":
      fi
      if [ -b /dev/$partition_name ]; then
        partition_dev="/dev/$partition_name";
      fi
      if [ ! -z "$partition_dev" ]; then
        blkid_data=": $(blkid $partition_dev)";
      else
        partition_dev="/dev/mapper/$partition_name";
      fi
      echo "  $partition_dev : $size $blkid_data";
      unset blkid_data
    done <<< "$kpartx_list"
  else
    local blkid_data=$(blkid $dev);
    if [ ! -z $blkid_data ]; then
      echo "  $dev : $blkid_data";
    fi
  fi
}

#d#==head2 diskhealth $dev : show disk health
#d#
#d# /usr/lib64/nagios/plugins/check_smart.pl
#d# /usr/lib/nagios/plugins/check_ide_smart
#d#
function diskhealth() {
  dev=$1

  # add to seperate function
  if [ ! -b $dev ]; then
    if [ -b /dev/$dev ]; then
      dev=/dev/$dev
    else
      if [[ "$dev" =~ c(.)p(.) ]]; then
        echo "controler " ${BASH_REMATCH[1]} " disk " ${BASH_REMATCH[2]}
        smartctl_param="-d 3ware ${BASH_REMATCH[2]} /dev/twa ${BASH_REMATCH[1]}"
      else
        echo "could not find dev $1";
        return 1
      fi
    fi
  fi

  # /usr/lib64/nagios/plugins/check_megaraid_sas.pl
  if [ -x /usr/lib64/nagios/plugins/check_megaraid_sas.pl ]; then
    /usr/lib64/nagios/plugins/check_megaraid_sas.pl
  elif [ -x /opt/nagiostools/plugins/check_megaraid_sas.pl ]; then
    /opt/nagiostools/plugins/check_megaraid_sas.pl
  fi

  interface="ata"
  if [ -x /opt/nagiostools/plugins/check_smart.pl ]; then
    /opt/nagiostools/plugins/check_smart.pl -d $dev -i $interface
  elif [ -x /usr/lib/nagios/plugins/check_ide_smart ]; then
    /usr/lib/nagios/plugins/check_ide_smart -d $dev
  elif [ -x /usr/lib64/nagios/plugins/check_smart.pl ]; then
    /usr/lib64/nagios/plugins/check_smart.pl -d $dev
  else
    smartctl_data=$(smartctl -a $dev)
    echo "$smartctl_data"
  fi
}

#d#==head2 disktest $dev : test with badbocks or other tools for bad-sectors and other errors
#d#
#d# we should have something like "locking"
#d#
#d# result is stored to: a "global git" would be nice :)
#d#
#d# tools used:
#d#  badblocks : default ? read , rw , rw-destructiv (-w)
#d#  smartctrl : (with script /opt/nagiostools/plugins/check_smart.pl)
#d#
function disktest() {
  local output_dir smartctl_param
  dev="$1"
  shift
  if [ -z "$dev" ]; then
    echo "disktest \$dev d(ryrun) t(est) f(force) (w)ritemode (b)adblocks (s)martctr (n)ohup";
    return 1;
  fi
  if [[ "$@" =~ t ]]; then
    run_mode="test";
  elif [[ "$@" =~ f ]]; then
    run_mode="force";
  fi
  if [ ! /usr/bin/time ]; then
    echo "/usr/bin/time missing";
    kinst time;
  fi

# output dir
  if [ -z "$EENV_SCRIPTDIR" ]; then
    if [ ! -d . ]; then
      echo "could not find output_dir";
    else
      output_dir="."
    fi
  else
    output_dir="$EENV_VARDIR/$EENV_FQDN/inventory";
  fi
  echo "output_dir=$output_dir";
  if [ ! -d $output_dir ]; then
    echo " output_dir dosnt exist"; return 1;
  fi

# device
  if [ ! -b $dev ]; then
    if [ -b /dev/$dev ]; then
      dev=/dev/$dev;
    else
      if [[ "$dev" =~ c(.)p(.) ]]; then
        echo "controler " ${BASH_REMATCH[1]} " disk " ${BASH_REMATCH[2]};
        smartctl_param="-d 3ware ${BASH_REMATCH[2]} /dev/twa ${BASH_REMATCH[1]}";
      else
        echo "could not find dev $1";
        return 1;
      fi
    fi
  fi
  serial=$(diskserial $dev) || false;
  if [ "$?" != 0 ]; then
    echo "could not determin $serial";
  fi

  # diskhealth can do this
# smartctl
  if [[ "$@" =~ s ]]; then
    local output_file="$output_dir/smartctl.${serial}"

    if [ -x /opt/nagiostools/plugins/check_smart.pl ]; then
      /opt/nagiostools/plugins/check_smart.pl -d $dev -i ata
    fi
    if [ -z "$smartctl_param" ]; then
      smartctl_param="$dev"
    fi
    smartctl_data=$(smartctl -a $smartctl_param)

    #serial_no=$(echo "$smartctl_data" |grep "Serial Number:" |cut -d: -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    #serial_no=$(diskserial $dev)
    #echo "serial_no=($serial_no)";
    #if [ -z "$serial_no" ]; then
    #  echo "could not determine serial_no";
    #fi
    # -s = show progress , -w = write moude , -o = output file
    if [[ "$@" =~ t ]]; then
      #nohup time badblocks -p 1 -s -o badblocks.$DEVSER.$DEV /dev/$DEV &
      # offline, short, long, conveyance, force, vendor,N, select,M-N, pending,N,
      smartctl -t long $smartctl_param
      #time badblocks -p 1 -s -o badblocks.$serial_no $dev
    fi
  fi

# badblocks
  if [[ "$@" =~ b ]]; then
    output_file="$output_dir/badbocks.${serial}"
    if [ -r "$output_file" ]; then
      echo "$output_file exists, should i use -i(gnore) mode?";
      return 1
    fi
    #if getLock ; then ... maybe with a fork?
    exec_command=""
    exec_params="-p 1 -s " # -s progress , -v verbose
    # read only (default), -n nondestructive rw, -w destructive rw
    # -i : ignor blocks file, written with -o
    #exec_params="$exec_params -o $output_dir/badblocks_list.$serial_no";
    if [ "$TERM" != "screen" ] || [[ "$@" =~ n ]]; then
      exec_command="nohup"
      if [ -r nohup.out ]; then
        mv nohup.out nohup.out.$$
      fi
    fi
    if [ -x /usr/bin/time ]; then
      exec_command="$exec_command time"
    fi
    if [[ "$@" =~ t ]]; then
      exec_params="$exec_params -n"
    elif [[ "$@" =~ w ]]; then
      exec_params="$exec_params -w"
    fi
    exec_command="$exec_command badblocks $exec_params $dev"
    if [[ ! "$@" =~ f ]]; then
      #diskinfo $dev
      echo -e "disk will be destroyed (enter yes):"
      echo "$exec_command >$output_file 2>&1";
      read yes
      if [ "$yes" != "yes" ]; then
        return
      fi
    fi

    run_name=badblocks$(echo "${dev}_$@" |sed -e 's/[[:space:]]//g' -e 's/\///g');
    if [[ "$@" =~ d ]]; then
      echo "$exec_command >$output_file 2>&1"
    else
      echo "creating /var/run/$run_name";
      ( __startTask "$run_name" &&
        $exec_command >$output_file 2>&1;
        __endTask "$run_name" ) &
      sleep 1;
    fi
  fi
}

function __startTask() {
  if [ -r /var/run/$1 ]; then
    >&2 echo "lockfile exists";
    exit 1
  fi
  echo $$ >/var/run/$1
}
function __endTask() {
  rm /var/run/$1
}

complete -F _complete_disktest disktest
_complete_disktest() {
  if [ "${#COMP_WORDS[*]}" == 2 ]; then
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts=$(cd /dev; ls sd?);
    #opts=$(cd /sys/block;ls sd?);
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  else
    COMPREPLY=("use b=badblocks, s=smart, f=force,")
  fi
}

#d#==head2 diskserial $dev : get serial no
#d#
function diskserial() {
  local dev="$1";
  local serial;
  local devname;
  if [ ! -b "$dev" ]; then
    if [ -b /dev/$dev ]; then
      dev="/dev/$dev";
    else
      if [[ $dev =~ c(.)p(.) ]]; then
        #echo "controler " ${BASH_REMATCH[1]} " disk " ${BASH_REMATCH[2]};
        serial=$(smartctl -d 3ware,${BASH_REMATCH[2]} -A /dev/twa${BASH_REMATCH[1]} |grep "Serial Number:" |cut -d: -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//');
      else
        1>&2 echo "could not find dev $dev ..";
        return 1;
      fi
    fi
  fi
  devname=${dev##*/};
  if [[ $devname =~ ^nvme ]]; then
    serial=$(cat nvme id-ctrl /dev/$item |grep "^sn" |);
  elif [[ $devname =~ ^loop ]]; then
    return 1;
  elif [[ $devname =~ ^md ]]; then
    serial="${BACKUP_HOSTNAME}-$devname";
  else
    if [ -x /sbin/udevadm ]; then
      serial=$(/sbin/udevadm info -q env -p /block/$devname |grep -i SERIAL_SHORT |cut -b 17-)
    elif [ -x /sbin/hdparm ]; then
      serial=$($BACKUP_SUDO hdparm -I "$dev" | grep "Serial Number:" |cut -d: -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' )
    else
      1>&2 "could not determine SN without tools";
      return 1;
    fi
  fi
  echo "$serial";
}


#d#==head2 raid : raid management (and standard interface for different tools)
#d#
#d# show
#d# start/stop ?
#d# add/remove
#d#
function raid() {
  local command=$1
  shift
  if [ "$command" == "show" ]; then
    raidmdadm $command
    #raid3ware $command
    #raidlsi $command
  elif [ "$command" == "add" ]; then
    raid_gettype $1
  else
    echo "command may be show,add,remove";
  fi
}

function raidmdadm() {
  local command=$1
  shift
  if [ "$command" == "show" ]; then
    #cat /proc/mdstat
    for dev in $(__disklist); do
      local mdadm_e
      mdadm_e=$(mdadm -E $dev 2>/dev/null);
      if [ "$?" != 0 ]; then continue; fi
      while IFS=":" read key value; do
        if [[ "$key" =~ Array.UUID ]]; then
          echo "$dev : $value "; #${BASH_REMATCH[1]}";
        fi
        #if [[ "$mdadm_e" =~ Array.UUID.(.*) ]]; then echo "$dev : ${BASH_REMATCH[1]}"; fi
      done <<< "$mdadm_e";
    done
  elif [ "$command" == "status" ]; then
    echo "not jet implemented";
  elif [ "$command" == "start" ]; then
    echo "not jet implemented";
  elif [ "$command" == "stop" ]; then
    echo "not jet implemented";
  elif [ "$command" == "add" ]; then
    echo "not jet implemented";
  elif [ "$command" == "remove" ]; then
    echo "not jet implemented";
  else
    echo "command may be show,add,remove";
  fi
}

function __raiddevlist() {
  for dev in $(__disklist); do
    if [[ "$LSPCI" =~ $dev ]]; then
      echo "ok";
    fi
  done
}

function raidlsi() {
  local command=$1
  shift
  if [ "$command" == "show" ]; then
    for dev in $(__raiddevlist); do
      echo "not jet implemented";
    done
  elif [ "$command" == "status" ]; then
    echo "not jet implemented";
  elif [ "$command" == "start" ]; then
    echo "not jet implemented";
  elif [ "$command" == "stop" ]; then
    echo "not jet implemented";
  elif [ "$command" == "add" ]; then
    echo "not jet implemented";
  elif [ "$command" == "remove" ]; then
    echo "not jet implemented";
  else
    echo "command may be show,add,remove";
  fi
}

function raid3ware() {
  local command=$1
  shift
  if [ "$command" == "show" ]; then
    echo "not jet implemented";
  elif [ "$command" == "status" ]; then
    echo "not jet implemented";
  elif [ "$command" == "start" ]; then
    echo "not jet implemented";
  elif [ "$command" == "stop" ]; then
    echo "not jet implemented";
  elif [ "$command" == "add" ]; then
    echo "not jet implemented";
  elif [ "$command" == "remove" ]; then
    echo "not jet implemented";
  else
    echo "command may be show,add,remove";
  fi
}

complete -F _complete_raid raid
_complete_raid() {
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  if [ "${#COMP_WORDS[*]}" == 2 ]; then
    opts="show add remove"
  else
    opts="$(__disklist)";
  fi
  if [[ ! -z ${cur} ]] ; then
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
  fi
}

#d#==head2 mountf: info about harddisks
#d# @category : disk
#d#
function mountf() {
  local last
  for last; do true; done

  dev=${last##*/}
  #echo $last
  if [ ! -d /mnt/$dev ]; then
    mkdir /mnt/$dev
  fi
  if cat /proc/mounts|grep "/mnt/$dev" >/dev/null; then
    echo "/mnt/$dev already mounted";
  else
    echo "ls /mnt/$dev"
    if mount $@ /mnt/$dev; then
      blkid $@
    fi
  fi
  ls -l /mnt/$dev
}

#d#==head2 mountf: info about harddisks
#d# @category : disk
#d#
function umountf() {
  for dir in $(ls /mnt); do
    umount $dir 2>/dev/null
  done
}


#d#==head2 qcowmount $file $mountpoint:
#d# @category : disk
#d#
function qcowmount() {
  num=0
  if [ "$1" == "" ]; then
    echo "qcowmount \$file \$mountpoint"
  fi
  modprobe nbd max_part=8
  qemu-nbd --connect=/dev/nbd$num $1
  fdisk /dev/nbd$num -l
}
function qcowumount() {
  qemu-nbd --disconnect /dev/nbd0
}




#d#==head2 lll : ls for "local" files, without files on different filesystems
#d# @todo: dosnt work?
#d# @category : disk ?

## vim: noai:ts=2:sw=2:set expandtab:tw=200:nowrap:
