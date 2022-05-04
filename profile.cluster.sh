#!/bin/bash
#d#


# Try to configure "cluster"...
# move @binben ?
export FQDN=$(hostname -f)
#HOSTNAME=$(hostname)
if echo "$FQDN"|grep "1" >/dev/null; then
  OH=$(echo "$FQDN"|sed 's/1/2/')
fi
if echo "$FQDN"|grep "2" >/dev/null; then
  OH=$(echo "$FQDN"|sed 's/2/1/')
fi
#_configure_2node_cluster

