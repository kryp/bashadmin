#!/bin/bash
################################################################################################ _SEC: REVISION CONTROL
################################################################################################
#d#
#d#==head1 REVISION CONTROL (cvs,sv,git,etc.)
#d# @category : revisioncontrol
#d#
#d# aliase for cvs : svncommit cvscommit cvscheck cvsd
#d#
#d#
#d#
#d# git clone --recursive
#d#
#d#

DEV=1.0
export DEV

declare -A c_envlist
declare -A kprofile_var_array

alias svncommit='svn commit -m "update"'
alias cvscommit='cvs commit -m "update"'
alias cvscheck='cvs -n update 2>&1 |grep "^[U|A|M]"'
alias cvsup='cvs -n update 2>&1'
alias cvsd='cvs diff'


if [ -d .git ]; then
  :
  #echo "dev profile PROFILE_SCRIPTDIR: $PROFILE_SCRIPTDIR"
  #ls -l .git
fi

alias editdev="$EDITOR $PROFILE_SCRIPTDIR/profile.dev.sh"

alias gitpushdevserver="git push origin master:dev/server"
#  git push origin master:dev/server
#  git merge origin/dev/server

# cd down:
alias gitcd='OLDIR=$PWD; while [ ! -d .git ]; do cd ..; if [ "$PWD" == "/" ]; then cd $OLDIR; break; fi; done'

function giti() {
  cat $HOME/.gitconfig
  gitcd
  if [ -r .venv ]; then
    cat .venv
  fi
  echo "* GIT REMOTE:"
  gitr
  echo "* GIT BRANCHES:"
  gitb
  echo "* GIT LOG:"
  gitl |tail -n 3
  echo
  echo "* GIT HOOKS:"
  giti_hooks
}

function giti_status() {
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


function giti_hooks() {
  git_hook_list="applypatch-msg fsmonitor-watchman pre-applypatch pre-commit pre-rebase prepare-commit-msg commit-msg post-update pre-commitpre-push pre-receive update"
  for h in $git_hook_list; do
    ls -l .git/hooks/$h 2>/dev/null
  done
}

function gitopen() {
  gitcd
  pa=$(pwd)
  pname=${pa##*/}
  ppath=${pa%/*}
  dname=${ppath##*/}
  echo "$dname/$pname"
  wslview "http://localhost:8082/git/local/$dname/$pname"
}

function githelp() {
  aliasg git
  cat <<"EOF"
gitkryp              : configure git
gitstashfrom $host [ $path ]  : ssh to host, create diff and apply (dir must be the same!)
gitstashto $host     : create diff, ssh to host and apply it there (dir must be the same!)
gitcpush             : commit and push
rccheckout           : checkout using projet-specific-tool ( git and svn support by checking $PROFILE_RC )

git push origin master:hosts/playstation
git show-ref

EOF
  :
}

#d#==head2 githookcommit: creates .git/hooks/pre-commit
#d# @category : revisioncontrol
#d#
function githookcommit() {
  gitcd
  if [ ! -d .git ]; then
    echo "not a git-repo"
    return 1
  fi
  if [[ -r .git/hooks/pre-commit && "$@" == "" ]]; then
    cat .git/hooks/pre-commit
  else
    cat >.git/hooks/pre-commit <<'EOF'
while [ ! -d .git ]; do cd ..; done
git log master --pretty=oneline | wc -l > build_number
git add build_number
dev_run_ci pre-commit
EOF
    echo "created .git/hooks/pre-commit"
  fi
}

#d#==head2 dev_run_ci: used from githookcommit
#d# @category : revisioncontrol
#d#
function dev_run_ci() {
  echo "running ci-tests..."
}

#d#==head2 gitkryp : create config, using $PROFILE_EMAIL
#d# @category : revisioncontrol
#d#
function gitkryp() {
  git config $@ user.name $PROFILE_USER
  git config $@ user.email $PROFILE_EMAIL
  git config $@ color.branch auto
  git config $@ color.status auto
  git config $@ color.diff auto
  #git config --global user.singingkey $gpg-key-id
}

function gitkrypglobal() {
  gitkryp --global
}


#d#==head2 rccheckout : checkout using projet-specific-tool ( git and svn support by checking $PROFILE_RC )
#d#
#d# $PROFILE_RC
#d#
function rccheckout() {
  #local RC=${PROFILE_RC}
  #echo $PROFILE_RC ($RC)
  if [ -z $1 ]; then
    echo "usage ${PROFILE_RC}/project"
    return
  fi
  local URL=${PROFILE_RC}/$1
  shift
  if ( echo $PROFILE_RC | grep git >/dev/null ); then
    echo "git clone ${URL} $@"
    git clone ${URL} $@
  elif ( echo $PROFILE_RC | grep svn >/dev/null ); then
    echo "svn checkout ${URL} $@"
    svn checkout ${PROFILE_RC} $@
  else
    echo "unkown method in ${PROFILE_RC}"
  fi
}

#d#==head2 gitstashfrom : git stash , and apply from another host                                                                                                                                                #d#
#d#
function gitstashfrom() {
  if [ -z "$1" ]; then
    echo "to wich host?"; return 1;
  fi
  local host=$1;
  local destpath=${2:-$PWD};
  local temp_dir="/tmp";
  local temp_name="patch.gitstashfrom";
  ssh $host "cd $destpath; git diff" >$temp_dir/$temp_name || return $?;
  git apply $temp_dir/$temp_name || return $?;
  echo "$temp_dir/$temp_name applied";
}

#d#==head2 gitmergepush()
#d#
#d#
function gitmergepush() {
  git pull
  git merge origin/dev/server
  git push
}

#d#==head2 gitstashto : git stash , and apply on another host (dir must be the same!)
#d#
#d#
function gitstashto() {
  if [ -z "$1" ]; then
    echo "to wich host?"; return 1;
  fi
  host=$1
  local temp_dir="/tmp";
  local temp_name="patch.gitstashto";
  git stash || return $?
  git stash show -p >$temp_dir/$temp_name || return $?
  scp $temp_dir/$temp_name $host:$temp_dir || return $?
  ssh $host "cd $PWD && git apply $temp_dir/$temp_name" || return $?
  echo "RUN: git stash drop"
}

#d#==head2 gitcpush : commit and push
#d#
#d#
function gitcpush() {
  git add -A &&
  git commit -m $@ &&
  git push
}

#d#==head2 gitcpush : commit and push
#d#
    #if [[ test -d $dir && cd $dir ]]; then
#d#
function gitdirstatus() {
  for dir in $(ls); do
    if test -d $dir && cd $dir; then
      echo "* $dir"
      local CURRENT_BRANCH=$(git branch 2>/dev/null|grep "*")
      if [[ "$CURRENT_BRANCH" != "* master" ]]; then
        echo "($CURRENT_BRANCH)"
        #giti_status
      fi
      #git status --porcelain
      #giti_hooks
      cd ..
    fi
  done
}

################################################################################################
function pythonenv() {
  python3 -m venv venv
  . venv/bin/activate
  type python
}

################################################################################################
################################################################################################
################################################################################################

# taken from "c"
if [ -d $HOME/gitkryp/kdesktop ]; then
  if ! echo "$PATH"|grep -q $HOME/gitkryp/kdesktop/bin; then
    PATH="$PATH:$HOME/gitkryp/kdesktop/bin"
  fi
fi

gitdirs="$HOME/gitkryp $HOME/gitextern"

if [ "$C_BUILDDIR" == "" ]; then C_BUILDDIR="/opt/build"; fi
if [ "$C_GITDIR" == "" ]; then
  if [ "$C_D" == "" ]; then
    C_D=$PROFILE_DOMAIN
  fi
  C_GITDIR=$HOME/git${C_D}
fi


