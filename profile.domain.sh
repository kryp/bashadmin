#!/bin/bash
#d#
################################################################## DOMAIN CONFIG
#d#==head1 DOMAIN CONFIG
#d#
#d# check for files
#d# set variables
#d# function: switchprofile
#d#
#d#
#d#
#d#
# check for environment specific files
# PROFILE_DOMAIN=${PROFILE_DOMAIN:=kryp}
# if [ -z "$(type -p envcd)" ]; then

#d#==head2 domain
#d#
function domainhelp() {
  cat <<'EOF'
switchdomain
switchprofile
switchresolve : see profile.wls

EOF
}

function determine_domain() {
  if [ -z "$PROFILE_DOMAIN" ]; then
    if [ -d $HOME/git/itoperation-env ]; then
      envcd_dir="$HOME/git/itoperation-env"; PROFILE_DOMAIN="kryp"
    elif [ -d $HOME/priv/itoperation-env ]; then
      envcd_dir="$HOME/priv/itoperation-env"; PROFILE_DOMAIN="kryp"
    elif [ -d /opt/itoperation-env ]; then
      envcd_dir="/opt/itoperation-env"; PROFILE_DOMAIN="kryp"
    elif [ -d /opt/kenv ]; then
      envcd_dir="/opt/kenv"; PROFILE_DOMAIN="kryp"
    elif [ -f "$HOME/.profile-kryp" ]; then
      PROFILE_DOMAIN="kryp"
    else
      PROFILE_DOMAIN="extern"
      echo "warning, could not determine PROFILE_DOMAIN"
    fi
  fi
  export PROFILE_DOMAIN
}


function switchdomain() {
  current_domain=$(readlink /etc/resolv.conf)
  echo "PROFILE_DOMAIN=$PROFILE_DOMAIN"
  echo "current_domain=$current_domain"
  if [ "$PROFILE_DOMAIN" == "test" ]; then
    echo "switching to kryp";
    PROFILE_DOMAIN="kryp"
  elif [ "$PROFILE_DOMAIN" == "kryp" ]; then
    PROFILE_DOMAIN="test"
  fi
}

function currentdomain() {
  current_domain=$(readlink /etc/resolv.conf)
  name=${current_domain##*.}
  echo "$name"
}

#d#==head2 switchprofile : switch between profiles
#d#
function switchprofile() {
  if [ -z $1 ]; then
    if [ "$PROFILE_DOMAIN" == "kryp" ]; then
      PROFILE_DOMAIN="test";
    else
      PROFILE_DOMAIN="kryp";
    fi
  else
    PROFILE_DOMAIN="$1";
  fi
}


## domain settings
if [ "$PROFILE_DOMAIN" == "test" ]; then
  REPOSITORY_SERVER='http://repo.test'
  REPOSITORY_UPLOADPATH=""
  PROFILE_USER="kryp"
  PROFILE_EMAIL="kryp@test"
  PROFILE_DEPLOY="scp $HOME/.profile-start.sh root@repo.test"
  PROFILE_PUPPET="puppet-vml"
  PROFILE_BACKUPHOST="backup"
  PROFILE_RC="ssh://gitolite@git.internal"
  PROFILE_LOGHOST="logserver"
  PROFILE_GIT="git"
  PIP_INDEX_URL="http://repo.test"
elif [ "$PROFILE_DOMAIN" == "kryp" ]; then
  REPOSITORY_SERVER='https://kryp.de'
  REPOSITORY_UPLOADPATH=""
  PROFILE_USER="kryp"
  PROFILE_EMAIL="kryp@kryp.de"
  PROFILE_DEPLOY="scp ~/.profile-start.sh root@repro:/var/www/www.kryp.de/htdocs/noc/profile-start.sh"
  PROFILE_PUPPET="puppet"
  PROFILE_BACKUPHOST=""
  PROFILE_RC="ssh://gitolite@mandala"
  PROFILE_LOGHOST="logserver"
  PROFILE_GIT="gitolite@git"
fi
export PROFILE_GIT PROFILE_BACKUPHOST


#if [ -r "$PROFILE_CONFIGFILE" ]; then . $PROFILE_CONFIGFILE; fi




determine_domain
if [ "$PROFILE_DEBUG" -gt 2 ]; then echo "PROFILE_DOMAIN=$PROFILE_DOMAIN"; fi


if [ -r $PROFILE_SCRIPTDIR/profile.domain.${PROFILE_DOMAIN}.sh ]; then
  . $PROFILE_SCRIPTDIR/profile.domain.${PROFILE_DOMAIN}.sh
fi

. $PROFILE_SCRIPTDIR/profile.domain.local.sh

