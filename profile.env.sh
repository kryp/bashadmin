#!/bin/bash
#d#


#d#==head2 e :  load (development) environment, $HOME/env_*
#d#
#d# diffrent ways to load and act on environments
#d#
function e() {
  env=$1
  if [ -z "$env" ]; then ls -d1 $HOME/env_*; env="py3"; fi
  if [ -d $HOME/env_${env} ]; then
    if [ -r $HOME/env_${env}/bin/activate ]; then . $HOME/env_${env}/bin/activate; fi
     if [ -d $HOME/env_${env}/env ]; then
      for item in $HOME/env_${env}/env/*; do . $i; done
    fi
    echo "done loding ${env}";
  elif [ -r /opt/env1/bin/activate ]; then
    . /opt/env1/bin/activate
  else
    if [ "$2" == "new" ]; then
      /usr/bin/python3 -m venv $HOME/env_${env}
    fi
    echo "could not find env_${env}";
    #ls -ld $HOME/env*
  fi
  python --version
}



