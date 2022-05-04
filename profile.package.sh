#!/bin/bash                                                                                                                                                                                                      #d#
#d#
#d#
#d#
#d#


function aptpurgeall() { apt-get purge $(dpkg -l | grep '^rc' | awk '{print $2}'); }



#function repairrpm() {
function rpmrepair() {
  mkdir /var/lib/rpm/backup/
  mv /var/lib/rpm/__db* /var/lib/rpm/backup/
  rpm --quiet -qa
  rpm --rebuilddb
  yum clean all
}

