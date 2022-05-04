#!/bin/bash
#d#
#d#
#d# seealso: networkdefault in profile.net
#d#



#d#==head2 puppetonce.service : create and enable systemd-config
#d#
function puppetonce.service() {
  cat >/etc/systemd/system/puppetonce.service<<EOF
[Unit]
Description=puppet-boot

[Service]
Type=oneshot #or simple
ExecStart=/opt/kpuppet/puppet-boot.sh

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable  puppetonce.service
}


#d#==head2 vm_image_sshkeys : regenerate ssh-keys
#d#
function vm_image_sshkeys() {
  rm /etc/ssh/ssh_host_*
  if [ "$PACKAGE_UTIL" == "dpkg" ]; then
    command="dpkg-reconfigure openssh-server"
  elif [ "$PACKAGE_UTIL" == "rpm" ]; then
    command="rpm"
  else
    echo "unkown PACKAGE_UTIL=$PACKAGE_UTIL"
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
    ssh-keygen -q -N "" -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key
    ssh-keygen -q -N "" -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
    ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
    return 1
  fi
  echo $command
  $command
}

#d#==head2 vm_image_installrequired
#d#
function vm_image_installrequired() {
  kinst policykit-1
}

function vm_image_init() {
  puppetonce.service
  vm_image_sshkeys
  vm_image_installrequired
}
