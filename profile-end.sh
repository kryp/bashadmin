
################################################################## load other "plugins" : END-PART

#d#==head2 load plugins
_plugins_skip="profile.disk"
if [ -r $PROFILE_SCRIPTDIR/profile.domain ]; then . $PROFILE_SCRIPTDIR/profile.domain; fi
for incfile in $(cd $PROFILE_SCRIPTDIR; ls profile.* 2>/dev/null |grep -v domain ); do
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

export PROFILE_ERROR

# if [ $# -gt 0 ]; then   $@ fi
## vim: noai:ts=2:sw=2:set expandtab:tw=200:nowrap:
