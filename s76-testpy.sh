#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
if [ -f s76setuptestpy.py ] && [ -f s76-setup-testpy.sh ]; then
    bash ./s76-setup-testpy.sh
fi
BURN_IN=0
ARGS=""

Help()
{
    echo "Usage: s76-testpy.sh [options]"
    echo ""
    echo "options:"
    echo "-h        Display this message and exit."
    echo "-b        Burn in test, run until stress-ng dies"
    echo "-s        Serial Number"
}

while getopts ":bhs:" option; do
   case $option in
        b) # Use specified stress-ng conf file
            BURN_IN=1;;
        h) # help text
            Help
            exit;;
        s) # Serial Number
            ARGS=" -s $OPTARG";;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
	        Help 1>&2
            exit 1;;
   esac
done

sudo bash -c "export PATH=$PATH:$SCRIPT_PATH/bin; gnome-terminal --geometry=821x547+30+559 --name=s76-testpy --title=System76-testpy -- bash -c  \"PYTHONPATH=$HOME/.local/lib/python3.10/site-packages ./test.py${ARGS}\""
sleep 5
sudo chown -R $LOCAL_USER:$LOCAL_USER $SCRIPT_PATH &>/dev/null
if [ $BURN_IN -gt 0 ]; then
    until pgrep -x "stress-ng" &>/dev/null; do
        sleep 15
    done
    while pgrep -x "stress-ng" &>/dev/null; do
        sleep 15
    done
    sudo kill $(pgrep -x "test.py")
fi