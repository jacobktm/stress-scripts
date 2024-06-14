#!/bin/bash

MALLOC=`nproc`
MALLOC_MAX=65536
MALLOC_BYTES="64K"
TIMEOUT=30

Help()
{
    echo "Usage: s76-stress-ng-malloc.sh [options]"
    echo ""
    echo "options:"
    echo "-h        Display this message and exit."
    echo "-m M      Set malloc-max option to M."
    echo "-n N      Set malloc-bytes option to N."
    echo "-t T      Set timeout in seconds to T."
}

while getopts ":hm:n:t:" option; do
    case $option in
       h) # help text
	  Help
	  exit;;
       m) # set malloc-max
	  MALLOC_MAX=$OPTARG;;
       n) # set malloc-bytes
	  MALLOC_BYTES=$OPTARG;;
       t) # set timeout
	  TIMEOUT=$OPTARG;;
      \?) # Invalid option
	  echo "Error: Invalid option"
	  Help
	  exit;;
    esac
done

if ! command -v stress-ng &> /dev/null
then
    sudo apt install -y stress-ng
fi

gnome-terminal --name=s76-stress-ng-malloc --geometry=868x25+-26+9 -- sudo stress-ng --malloc $MALLOC --maximize --oomable --verbose --timeout $TIMEOUT --malloc-max $MALLOC_MAX --malloc-bytes $MALLOC_BYTES --page-in
