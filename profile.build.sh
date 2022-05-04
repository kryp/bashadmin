#!/bin/bash                                                                                                                                                                                                      ##################################################################
#d#==head1 NAME
#d#

function kprofiledeploy() {
  echo "kprofiledeploy"
  kprofilebuild
  output_file="/tmp/profile-start.sh.$PROFILE_DOMAIN"
  if [ "$PROFILE_DOMAIN" == "kryp" ]; then
    location="root@repro:/var/www/htdocs/noc/profile-start.sh"
  else
    echo "unkown domain $PROFILE_DOMAIN"
  fi
  echo "$output_file $location"
  scp $output_file $location
}

function kprofilebuild() {
  output_file="/tmp/profile-start.sh.$PROFILE_DOMAIN"
  echo "PROFILE_DOMAIN=$PROFILE_DOMAIN"
  cp $PROFILE_SCRIPTDIR/profile-start.sh $output_file

  module_list="$(cd $PROFILE_SCRIPTDIR; ls -1 profile.*|grep -v domain)"
  ALL_MODULES=""
  for module_file in $module_list; do # |grep -v profile-end
    ALL_MODULES="$ALL_MODULES ${module_file:8:-3}"
  done
  if [ "$PROFILE_DOMAIN" == "kryp" ]; then
    MODULES="$ALL_MODULES domain.kryp"
  else
    echo "unkown domain $PROFILE_DOMAIN"
  fi
  MODULES="$MODULES"
  for m in $MODULES; do
    echo "importing $m";
    cat $PROFILE_SCRIPTDIR/profile.$m.sh >>$output_file
  done
  cat $PROFILE_SCRIPTDIR/profile-end.sh >>$output_file
}


