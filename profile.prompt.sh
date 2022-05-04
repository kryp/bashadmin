#!/bin/bash
################################################################################################ _SEC: PROMPT
################################################################################################
#d#==head1 PROMPT (prompt)
#d#
#d# @todo: _pschecksum
#d#
#d# ansi colors
#d#

#d#==head1 NAME
#d#

PROMPT_INFO=""
PS_COLOR="${C_BLACK}"
# SCM_THEME_PROMPT_DIRTY=' ✗'
# SCM_THEME_PROMPT_CLEAN=' ✓'

#d#==head3 _prompt_backdir()
#d#
function _prompt_backdir() {
# check parrent paths for git
  if [ ! -z "$K_GIT_EXISTS" ]; then
    local CPATH=$PWD
    local OLDPATH=$PWD
    while [ "$CPATH" != "" ]; do
      CPATH=${CPATH%/*}
      cd $CPATH
      #PS1+="$(_psupdate2)";
      PS1+="$(_psrepository)";
      if [ -r $CPATH/000kindex ]; then
        PS1+="(kindex:$CPATH)";
      fi
      if [ -r $CPATH/.git ]; then
        PS1+="(git:$CPATH)";
      fi
    done
    cd $OLDPATH
  fi
}

#d#==head3 _psrepository : get repository information (recursive!)
#d#
function _psrepository() {
  local CVSINFO=CVS/Root
  if [ -e $CVSINFO ]; then
    local REPO=$(cat $CVSINFO)
    echo "[C:$REPO]"
  fi
  if [ -e .SVN ] || [ -e .svn ] ; then
    local INFO=$(svn info 2>/dev/null|grep Revision: |awk '{ print $2 }')
    echo "[S:$INFO]"
  fi
  if [ -e .git ]; then
    # https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
    # https://github.com/magicmonty/bash-git-prompt/
    #PROMPT_INFO="$PROMPT_INFO GIT"
    local CURRENT_BRANCH=$(git branch 2>/dev/null|grep "*")
    local message="something went wrong";
    if [ -e .git/ORIG_HEAD ]; then
      LOCAL=$(git rev-parse @{0} 2>/dev/null)
      REMOTE=$(git rev-parse @{u} 2>/dev/null)
      BASE=$(git merge-base @{0} @{u} 2>/dev/null)
      if [ "$LOCAL" == "$REMOTE" ]; then
          message="✓"
      elif [ "$LOCAL" == "$BASE" ]; then
          message="↓"
      elif [ "$REMOTE" == "$BASE" ]; then
          message="↑"
      else
          message="↓↑"
      fi
      git_status=$(git status --porcelain 2>/dev/null);
      if [ "$git_status" != "" ]; then
        message="$message U"
      fi
    else
      message="X"
    fi
    if [ -r .git/hooks/pre-commit ]; then
      message="$message H"
    fi
    echo "[G:$CURRENT_BRANCH $message]"
  fi
}

#d#==head3 _pschecksum : check checksum and version
#d#
function _pschecksum() {
  if [ -r ~/.profile-start.sh ]; then
    kversion_file_version=$(grep "^export KVERSION=" ~/.profile-start.sh)
  else
    kversion_file_version=$(grep "^export KVERSION=" $PROFILE_SCRIPT)
  fi
  #echo "($kversion_file_version)($KVERSION)";
  if [ "export KVERSION='$KVERSION'" != "$kversion_file_version" ]; then
    echo -en "[RELOAD] "
  fi
  if [ ! -z "$START_SSH_AUTH_SOCK" ]; then
    if [[ -r "$START_SSH_AUTH_SOCK" ]]; then
      echo -en "[A] "
    else
      echo -en "[XA] "
    fi
  fi
  if [ "$PROFILE_DOMAIN" == "kryp" ]; then
    if [ ! -L $HOME/.profile-start.sh ]; then
      echo -en "[LINK] "
    fi
  fi
}

#d#==head3 _check_lastupdate: check last update (DISABLED)
#d#
function _check_lastupdate() {
  PSCURRENTDATE=$(date +%s)
  TIMEDIFF=$(($PSCURRENTDATE-$PSLASTUPDATE))
  # 86400 = on day
  if [ $TIMEDIFF -gt 3 ]; then
    echo "updating ($TIMEDIFF) ($PSLASTUPDATE)($PSCURRENTDATE)"
    PSLASTUPDATE=$PSCURRENTDATE;
  fi
  #export PSLASTUPDATE
  #echo "CURRENT ($TIMEDIFF) ($PSLASTUPDATE)($PSCURRENTDATE)"
}



#d#==head3 _psupdate1 : creates the "ps" line by :
#d#
#d#
function _psupdate1() { # (first line) puppet, load, last update, etc.
  PROMPT_TIME=$(date +%s)
  echo -en "($PROFILE_DOMAIN) "

  if [ "$VIRTUAL_ENV" != "" ]; then
    VENV="${VIRTUAL_ENV##*/}"
    #echo -en "(e:${VENV:4:-1}) ";
    echo -en "(e:${VENV}) ";
  fi

  if [[ "$PROFILE_PARRENT" =~ ^/bin/bash ]]; then
    echo -en "$COLOR_Red[bash]$COLOR_RESET ";
  fi
  echo -en "$EENV_VIRT "
  echo -en "[$EENV_SERVICE_LIST ] "
  echo -en "\033[1;31m"

  if [ "$PROFILE_DOMAIN" == "kryp" ] && [ "$K_GIT_EXISTS" != 1 ]; then
    echo -en "[GIT] "
  fi

  # upgraded to work with local=de
  export PROMPT_LOADAVG=$(uptime | sed -e "s/.*load average: \(.*[.,]..\), \(.*[.,]..\), \(.*[.,]..\)/\1/" -e "s/ //g")
  if [[ "$PROMPT_LOADAVG" =~ , ]]; then
    PROMPT_LOADAVG=$(echo $PROMPT_LOADAVG |tr ',' '.')
  fi
  if [ $(echo "$PROMPT_LOADAVG >= 1" | bc  -l) -eq 1 ]; then
    echo -en "[L:$PROMPT_LOADAVG] "
  fi
  #echo -en "\033[1;32m[L:$PROMPT_LOADAVG]"

  JOBCOUNT=`_jobcount`;
  if [ "$JOBCOUNT" -gt 0 ]; then
    echo -en "[J:${JOBCOUNT}] "
  fi

  if [ "$PROFILE_DOMAIN" == "fdsg" ]; then
    #_detect-puppet
    #if ! /usr/lib64/nagios/plugins/check_puppet.sh >/dev/null; then echo -en "\033[1;31m[P] " fi
    if [ -z "$PUPPET_STATE" ]; then
      echo -en "\033[1;31m[P] "
    fi
  elif [ "$EENV_SCRIPTDIR" != "" ]; then
    kenv_last_fetch="$(stat -c %Y $EENV_SCRIPTDIR/.git/FETCH_HEAD)"
    kenv_fetch_time_diff=$(($PROMPT_TIME - $kenv_last_fetch));
    if [ "$kenv_fetch_time_diff" -gt 172800 ]; then # older than 2 days
      kenv_fetch_time_diff_nice=$(date -d @$kenv_fetch_time_diff +"%Hh %Mm");
      echo -en "[K:$kenv_fetch_time_diff_nice] "
    else
      :
    fi
  elif [ "$envcd_dir" != "" ]; then
    :
  else
    echo -en "[NM] "
  fi
  if [ -z "$PUPPET_FACTER" ]; then
    echo -en "[NP] "
  fi
  if [ -s /tmp/checks ]; then
    CHECKLIST="$(cat /tmp/checks)";
    while read checkname output; do
      if ((BASH_VERSINFO[0] > 3)) && ((BASH_VERSINFO[1] < 4)); then
        output=$checkname
      else
        output=${checkname:0:-1}
      fi
      echo -n "[$checkname] ";
    done <<<"$CHECKLIST"
  fi
  if [ -d /tmp/nagiostools/ ]; then
    local list_of_services=($(ls /tmp/nagiostools/));
    if [[ ${#list_of_services[*]} -gt 0 ]]; then
      echo -en "[${list_of_services[@]}] "
    fi
  fi
  running_vim=$(ps aux |grep [v]im)
  if [ ! -z "$running_vim" ]; then
    echo -en "[VI] "
  fi
  _pschecksum # shows "RELOAD" if needed
  #_check_lastupdate
  #_tile_update
  echo -en "\033[0;37m"
}

#d#==head3 _psupdate2() : (second line) git repository
#d#
function _psupdate2() { # (second line) git repository
  if [ ! -z "$K_GIT_EXISTS" ]; then
    _psrepository
  fi
}

#d#==head2 __prompt_command() : nice way to make a nice command prompt (needs export PROMPT_COMMAND=__prompt_command)
#d#
function __prompt_command() {
  local EXIT="$?"             # This needs to be first
  PROMPT_TIME=$(date +%s)
  #local PS1
  PS1=""
  # user+hostname+dir
  #PS1+="$PS_COLOR\[\033[1;40m\]..[\u][\H][\w]\[\033[1;40m\]"
  PS1+="\[\e[1;40;37m\]"
  PS1+="[\u]"
  PS1+="[\H]"
  PS1+="[\w]\[\033[1;40m\]"
  #PS1+="\[\033[1;40;32m\]..[\u][\H][\w]\[\033[1;40m\]"
  #PS1+="\E[00;1;40;32m [\u][\H][\w]\[\033[1;40m\]"
  PS1+='['${TERM_COLOR}'${TERM}\[\033[1;40m\]]'
  #
  #	PS1+='[j:\j, t:$cur_tty ]'
  #PS1+='[VER:${VERSION_NUM} ]'
  #PS1+="$PROMPT_INFO"
  #PS1+="[$(date +%D) \t]";
  PS1+="[$(date +'%y/%m/%d') \t]";
  PS1+=" \[\033[0m\] ";
  PS1+="$(_psupdate1)\n";
  PS1+="$(_psupdate2)";
  #`_psupdate2` [$(date +%D) \t ] [ $? ] \$>'

  local screen_title='';
#  if [ "$TERM" == "screen.xterm-256color" ]; then
#    #export TERM="xterm"
#    PS1+="TERM";
#  fi
  if [ "$TERM" == "screen" ]; then
    screen_title='\[\033k\033\\\]';
  fi
  if [ "$PROFILE_ERROR" != "" ]; then
    PS1+="${COLOR_Red}[${PROFILE_ERROR}] ${COLOR_RESET}"  # Add red if exit code non 0
  fi
  if [ $EXIT != 0 ]; then
    PS1+="${COLOR_Red}${EXIT}${screen_title}> ${COLOR_RESET}"  # Add red if exit code non 0
  else
    PS1+="${COLOR_Gre}${screen_title}> ${COLOR_RESET}"
  fi
  #PS1+="${RCol}@${BBlu}\h ${Pur}\W${BYel}$ ${RCol}"
  #PS1='\[\033k\033\\\]\u@\h:\w$ ' # WORKS
}


#################################### set term-color and prompt
cur_tty=$(tty | sed -e "s/.*tty\(.*\)/\1/")

TERM_COLOR="\[\033[1;44m\]" # blue
if [ "$TERM" == "screen" ]; then # magenta
  TERM_COLOR="\[\033[1;45m\]"
fi
PS_COLOR="${C_BLACK}"
if [ `hostname` == "dt-start" ] || [ `hostname` == "xesar" ] || [ `hostname` == "ass192" ]; then
  PS_COLOR="\[\033[1;34m\]"
fi

#echo "color: $PS_COLOR";

PS_DEBIAN='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

#PS1=$PS_FULL
export PROMPT_COMMAND=__prompt_command

alias promptdebian='PS1=$PS_DEBIAN';
alias promptfull='PS1=$PS_FULL';





