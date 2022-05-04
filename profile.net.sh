#!/bin/bash
################################################################################################ _SEC: NETWORK
################################################################################################
#d#==head1 NETWORK
#d#
#d#==head2 iph : ip command help
#d# @category : network
#d#
#echo "SERVER PROFILE"

#d#==head2 ip route list table all (still needs some work)
#d# @category : network
#d#
function iprouteall() {
  local rulelist=$(ip rule |awk '{ print $1 }');
  for rule in $rulelist; do
    ip route list table $rule
  done
}

#d#==head2 networkdefault : creates /etc/systemd/network/default.network
#d#
function networkdefault() {
  printf "[Match]\nName=en*\n\n[Network]\nDHCP=both\n" > /etc/systemd/network/default.network
  ls -l /etc/systemd/network/default.network
}

#d#==head2 netdetect : show network-stack
#d#
#d#
function netdetect() {
  echo "net"
  if [ -x /usr/sbin/ifup ]; then
    ls -l /usr/sbin/ifup
  fi
  if [ -r /etc/udev/rules.d/70-persistent-net.rules ]; then
    ls -l /etc/udev/rules.d/70-persistent-net.rules
    cat /etc/udev/rules.d/70-persistent-net.rules
  fi
  if [ -r /udev/rules.d/70-persistent-net.rules ]; then
    ls -l /udev/rules.d/70-persistent-net.rules
  fi
# debian
  if [ -r /etc/network/interfaces ]; then
    ls -l /etc/network/interfaces
    grep "iface" /etc/network/interfaces
  fi
# centos : /etc/sysconfig/network-scripts
  if [ -d /etc/sysconfig/network-scripts ]; then
    ls -l /etc/sysconfig/network-scripts/eth*
  fi
# systemd
  if [ -d /etc/systemd/network ]; then
    find /etc/systemd/network -ls
  fi
# network-manager
  if [ -r /etc/NetworkManager/NetworkManager.conf ]; then
    ls -l /etc/NetworkManager/NetworkManager.conf
  fi
# wpa
  if [ -r /etc/wpa_supplicant.conf ]; then
    ls -l /etc/wpa_supplicant.conf
  fi
}

alias netshow="netdetect"
alias firewalllist="firewall-cmd --list-all-zones"

function firewalll() {
  zones=$(firewall-cmd --get-zones)
  for z in $zones; do
    if [[ "$z" == "block" || "$z" == "drop" || "$z" == "public" ]]; then continue; fi
    firewall-cmd --list-all --zone $z
  done;
}


function iptablessshdrop() {
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -I INPUT -p tcp --dport 22 -j DROP
}

#d#==head2 showipt : show all iptables
#d#
#d#
function showipt ()
{
    local TABLELIST="filter";
    local TABLENAME="";
    if [ "$1" == "" ]; then
        TABLELIST='filter nat mangle raw';
    else
        TABLENAME="$1";
    fi;
    for TABLE in $TABLELIST;
    do
        echo "### $TABLE";
        iptables -t $TABLE -L $TABLENAME -v -n --line-number;
    done
}

function iph() {
  cat <<'EOF'
ip-link
ip [ OPTIONS ] link  { COMMAND | help }
ip link add [ link DEVICE ] [ name ] NAME [ txqueuelen PACKETS ] [ address LLADDR ] [ broadcast LLADDR ] [ mtu MTU ] [ index IDX ] ...  type TYPE [ ARGS ]
ip link delete { DEVICE | group GROUP } type TYPE [ ARGS ]
ip link set { DEVICE | group GROUP } { up | down | arp { on | off } |
ip link show [ DEVICE | group GROUP | up | master DEVICE | type TYPE ]
 OPTIONS := { -V[ersion] | -h[uman-readable] | -s[tatistics] | -r[esolve] | -f[amily] { inet | inet6 | ipx | dnet | link } | -o[neline] | -br[ief] }
 TYPE := [ bridge | bond | can | dummy | hsr | ifb | ipoib | macvlan | macvtap | vcan | veth | vlan | vxlan | ip6tnl | ipip | sit | gre | gretap | ip6gre | ip6gretap | vti |
               nlmon | ipvlan | lowpan | geneve ]

ip-neighbour
ip neigh { add | del | change | replace } { ADDR [ lladdr LLADDR ] [ nud { permanent | noarp | stale | reachable } ] | proxy ADDR } [ dev DEV ]
ip neigh { show | flush } [ proxy ] [ to PREFIX ] [ dev DEV ] [ nud STATE ]

ip-address
ip addr add 172.17.7.163 dev eth0
ip address { add | change | replace } IFADDR dev IFNAME [ LIFETIME ] [ CONFFLAG-LIST ]
ip address del IFADDR dev IFNAME [ mngtmpaddr ]
ip address { show | save | flush } [ dev IFNAME ] [ scope SCOPE-ID ] [ to PREFIX ] [ FLAG-LIST ] [ label PATTERN ] [ up ]
 IFADDR := PREFIX | ADDR peer PREFIX [ broadcast ADDR ] [ anycast ADDR ] [ label LABEL ] [ scope SCOPE-ID ]
 SCOPE-ID := [ host | link | global | NUMBER ]
 FLAG := [ permanent | dynamic | secondary | primary | [ - ] tentative | [ - ] deprecated | [ - ] dadfailed | temporary | CONFFLAG-LIST ]
 CONFFLAG := [ home | mngtmpaddr | nodad | noprefixroute ]

ip-route
ip route get to 10.241.66.181
ip route add to 10.241.0.0/16 dev bond0.18
ip route add to 10.241.0.0/16 via 172.19.10.7 dev eth0
ip [ ip-OPTIONS ] route  { COMMAND | help }
 SELECTOR := [ root PREFIX ] [ match PREFIX ] [ exact PREFIX ] [ table TABLE_ID ] [ proto RTPROTO ] [ type TYPE ] [ scope SCOPE ]
 ROUTE := [ NODE_SPEC ] [ INFO_SPEC ] := [ TYPE ] PREFIX [ tos TOS ] [ table TABLE_ID ] [ proto RTPROTO ] [ scope SCOPE ] [ metric METRIC ]
 FAMILY := [ inet | inet6 | ipx | dnet | mpls | bridge | link ]
 TYPE := [ unicast | local | broadcast | multicast | throw | unreachable | prohibit | blackhole | nat ]
 TABLE_ID := [ local| main | default | all | NUMBER ]

ip-rule
ip [ OPTIONS ] rule [ list | add | del | flush | save ] SELECTOR ACTION
 SELECTOR := [ from PREFIX ] [ to PREFIX ] [ tos TOS ] [ fwmark FWMARK[/MASK] ] [ iif STRING ] [ oif STRING ] [ pref NUMBER ]
 ACTION := [ table TABLE_ID ] [ nat ADDRESS ] [ realms [SRCREALM/]DSTREALM ] SUPPRESSOR
 TABLE_ID := [ local | main | default | NUMBER ]
ip rule del pref 10000

ip-monitor
ip monitor all
ip [ ip-OPTIONS ] monitor [ all | OBJECT-LIST ] [ file FILENAME ] [ label ] [ all-nsid ] [ dev DEVICE ]

ip-addrlabel
ip-l2tp
ip-mroute
ip-maddress ( multicast )
ip-netns
ip-ntable
ip-tcp_metrics
ip-tunnel
ip-xfrm
EOF
}


#d#==head2 convertnumber (
#d#
#d# hex2oct hex2dec hex2bin
#d# dec2oct dec2hex dec2bin
#d#
alias hex2oct="convertnumber hex oct "; alias hex2dec="convertnumber hex dec "; alias hex2bin="convertnumber hex bin ";
alias dec2oct="convertnumber dec oct "; alias dec2hex="convertnumber dec hex "; alias dec2bin="convertnumber dec bin ";
alias bin2oct="convertnumber bin oct "; alias bin2hex="convertnumber bin hex "; alias bin2dec="convertnumber bin dec ";
function convertnumber() {
  if [ -z $3 ]; then echo "param missing"; fi
  value=$(echo $3| tr '[:lower:]' '[:upper:]' );
  local ibase; local obase;
  case $1 in
    "hex" ) ibase="16";;
    "dec" ) ibase="10";;
    "bin" ) ibase="2";;
    * ) echo "unkown ($1)"; return;;
  esac;
  case $2 in
    hex ) obase="16";;
    dec ) obase="10";;
    bin ) obase="2";;
    * ) echo "unkown ($1)"; return;;
  esac
  echo "obase=$obase;ibase=$ibase;$value" |bc
}

#d#==head2 netdetect : show network-stack
#d#
#d#
function cleaript() {
  iptables -F
  iptables -X
  iptables -t nat -F
  iptables -t nat -X
  iptables -t mangle -F
  iptables -t mangle -X
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
}

# if [ $# -gt 0 ]; then   $@ fi
## vim: noai:ts=2:sw=2:set expandtab:tw=200:nowrap:
