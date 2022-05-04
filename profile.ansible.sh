#!/bin/bash                                                                                                                                                                                                      #d#
#d#
#d#
#d#
#d#


# ~/.ansible/collections/ansible_collections
ANSIBLE_BASE=.

export hl=''
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt

alias ae='$EDITOR $ANSIBLE_BASE/$ANSIBLE_INVENTORY'
alias aconfig='$EDITOR /etc/ansible/ansible.cfg'
alias adoc='ansible-doc'
alias ap='ansible-playbook'
alias aill='ansible all --list-hosts'
alias ail='ansible-inventory --list'
alias aig='ansible-inventory  --graph'
alias ahosts='vi /etc/ansible/hosts'
alias adebug="export ANSIBLE_DEBUG=1"
alias adebugoff="export ANSIBLE_DEBUG=0"
alias ashowskip="export ANSIBLE_DISPLAY_SKIPPED_HOSTS=false"
# ansible hostname -i inventory_source -m ansible.builtin.ping

function avault() {
  if [ -z "$2" ]; then
    es="$(powershell.exe -NoProfile Get-Clipboard 2>&1 | tr -d '\r')"
  else
    es=$2
  fi
  echo "var: $1 pass: $es"
  ansible-vault encrypt_string "$es" --name "$1"
}


function ahelp() {
  cat <<EOF
ANSIBLE_VAULT_PASSWORD_FILE: $ANSIBLE_VAULT_PASSWORD_FILE
ANSIBLE_INVENTORY: $ANSIBLE_INVENTORY
ANSIBLE_CONFIG: $ANSIBLE_CONFIG
ANSIBLE_HASH_BEHAVIOUR: $ANSIBLE_HASH_BEHAVIOUR
ANSIBLE_FACT_PATH: $ANSIBLE_FACT_PATH

ail : ansible-inventory --list

ls ~/.ansible/collections/* : $(ls ~/.ansible/collections/*)
ansible-galaxy list

EOF
}


function aigg() {
  grep $1 $ANSIBLE_INVENTORY
}
