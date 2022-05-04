#!/bin/bash



alias puppetcatalog="puppet catalog find |tee pc-$HOST.json"
alias puppetedit="vi /opt/kpuppet/hieradata/nodes/$(hostname -f).yaml"
alias pcd="cd /opt/kpuppet"


CATALOG_SERVER="https://test/puppet/catalog"



#d#==head3 _detect-puppet : check if puppet-statefile is found
#d#
function _detect-puppet() {
  echo "PUPPET_FACTER=$PUPPET_FACTER"
  echo "PUPPET_ENV=$PUPPET_ENV"
  echo "PUPPET_STATE=$PUPPET_STATE"
  for puppet_state_list_item in $PUPPET_STATE_LIST; do
    if [ -r $puppet_state_list_item ]; then
      local LASTRUN=$(stat -c %Y $puppet_state_list_item)
      local difftime=$(($PROMPT_TIME-$LASTRUN))
      local difftimestr=$(date -d $difftime +"%H:%M:%S")
      if [ $difftime -gt 3600 ]; then
        echo -en "\033[1;31m[P $difftimestr] $puppet_state_list_item ${COLOR_RESET}"
      else
        echo -en "\033[1;32m[P $difftimestr] $puppet_state_list_item ${COLOR_RESET}"
      fi
      return
    fi
  done
  if [ -z "$LASTRUN" ]; then
    echo -e "${C_RED} [NP] ${C_RESET}"
  fi
}

#d#==head2 puppet_testing() : run catalog, apply and post catalog to CATALOG_SERVER
#d#
function puppet_testing() {
  CATALOG=catalog.json
  puppet catalog find >$CATALOG
  puppet apply --catalog $CATALOG
  curl_opts="-d '@$CATALOG' -X POST --header "Content-Type:application/json""
  curl $curl_opts $CATALOG_SERVER
}

#d#==head2 _configure_puppet : check for puppet environment
#d#
#d# exports: PUPPET_FACTER PUPPET_ENV PUPPET_STATE
#d#
function _configure_puppet() {
  #PUPPET_FACTER_LIST="/etc/facter/facts.d /etc/puppet/facter/facts.d/facts.txt /etc/puppetlabs/facter/facts.d/facts.txt"
  #PUPPET_FACTER_LIST="/etc/puppet/facter/facts.d/facts.txt /etc/puppetlabs/facter/facts.d/facts.txt"
  PUPPET_FACTER_LIST="/etc/puppet/facter/facts.d /etc/puppetlabs/facter/facts.d /etc/facter/facts.d"
  for PUPPET_FACTER_ITEM in $PUPPET_FACTER_LIST; do
    if [ -d "$PUPPET_FACTER_ITEM" ]; then
      PUPPET_FACTER="$PUPPET_FACTER_ITEM/facts.txt";
      if [ ! -e "$PUPPET_FACTER" ]; then
        echo "role=base" >$PUPPET_FACTER
      fi
    fi
  done
  PUPPET_ENV_LIST="/etc/puppetlabs/code/environments/production/manifests/site.pp /etc/puppet/code/environments/production/manifests/site.pp";
  for PUPPET_ENV_ITEM in $PUPPET_ENV_LIST; do
    if [ -e "$PUPPET_ENV_ITEM" ]; then
      PUPPET_ENV=$PUPPET_ENV_ITEM;
    fi
  done

  #puppet_state_list
  PUPPET_STATE_LIST="/opt/puppetlabs/puppet/cache/state/state.yaml /var/lib/puppet/state/last_run_summary.yaml /var/cache/puppet/state/state.yaml"
  for PUPPET_STATE_ITEM in $PUPPET_STATE_LIST; do
    if [ -e "$PUPPET_STATE_ITEM" ]; then
      PUPPET_STATE=$PUPPET_STATE_ITEM;
    fi
  done
  #if [ -z "$SSH_CONNECTION" ]; then
  if [ "$SHELL_I" == "interactive" ]; then
    #echo "PUPPET_FACTER=$PUPPET_FACTER"
    #echo "PUPPET_ENV=$PUPPET_ENV"
    #echo "PUPPET_STATE=$PUPPET_STATE"
    :
  fi
}
_configure_puppet


if [ -r /var/log/puppetlabs/puppet/puppet.log ]; then
  alias pul='tail -f /var/log/puppetlabs/puppet/puppet.log'
else
  alias pul='tail -f /var/log/puppet/puppet.log'
fi

alias pule='tail -n 100 /var/log/puppet/puppet.log |grep err'
alias puo='/etc/init.d/puppet once'
alias pa='puppet agent --server $PROFILE_PUPPET'
#alias puo='/etc/init.d/puppet once'
#alias pa='puppet agent --server $PROFILE_PUPPET'
alias patt="puppet agent --server $PROFILE_PUPPET --test"
alias patn="puppet agent --server $PROFILE_PUPPET --test --noop"
alias pact="puppet agent --server $PROFILE_PUPPET --environment=tewt --test"
alias pacn="puppet agent --server $PROFILE_PUPPET --environment=test --test --noop"
alias paa="puppet apply --environment production --test $PUPPET_ENV"
alias puppett="puppet agent -t"
alias puppetenable="puppet agent --enable"
alias puppetdisable="puppet agent --disable"
alias paanoop="puppet apply --environment production --test $PUPPET_ENV --noop"
alias pamodule="puppet module list --tree"
alias pamoduledir="puppet module list --tree --modulepath "

alias pae="vi $PUPPET_FACTER"
if [ "$PUPPET_FACTER" != "" ]; then
  alias peditrole="vi /opt/kpuppet/data/role/$($FACTER_BIN role)/common.yaml"
fi


