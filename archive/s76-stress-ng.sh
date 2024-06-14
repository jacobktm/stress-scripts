#!/bin/bash

LTEQ16G=""
D_TO_MB=1000
if grep -q "kB" /proc/meminfo; then
    D_TO_MB=1000
else
    D_TO_MB=1000000
fi

TOTAL_MEM_KB=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
TOTAL_MEM=$((TOTAL_MEM_KB / D_TO_MB))
STRESS_NG_PATH="${HOME}/stress-ng/stress-ng"
if (( $TOTAL_MEM <= 17000 ));
then
    LTEQ16G="-lteq16G"
fi
RESERVED_MEM=$((TOTAL_MEM / 15))
INTEGRATED_GRAPHICS=0
OS_STR=`lsb_release -a 2>/dev/null | grep Description | awk '{ print $2 $3 $4 }'`
CONFIG_FILE="default${LTEQ16G}.conf"
if [ $OS_STR == 'Pop!_OS20.04LTS' ];
then
    CONFIG_FILE="pop20.04${LTEQ16G}.conf"
fi
if [ $OS_STR == 'Ubuntu18.04.6LTS' ];
then
    CONFIG_FILE="ubuntu18.04${LTEQ16G}.conf"
fi
OPTIONS_STR=`tr '\n' ' ' < $CONFIG_FILE`

Help()
{
    echo "Usage: s76-stress-ng.sh [options]"
    echo ""
    echo "Options:"
    echo "-h       Display this message and exit."
    echo "-c F     Use specified config file F."
    echo "-i       Using Integrated Graphics."
}

while getopts "c:hi" option; do
    case $option in
        c) # Use specified config file
            CONFIG_FILE=$OPTARG;;
        h) # help text
	        Help
	        exit;;
        i) # integrated graphics
            INTEGRATED_GRAPHICS=1;;
        \?) # Invalid option
	        echo "Error: Invalid option."
	        Help
	        exit;;
    esac
done

if (( $RESERVED_MEM < 4000 ));
then
    RESERVED_MEM=4000
fi
if (( $RESERVED_MEM > 50000 ));
then
    RESERVED_MEM=50000
fi
if (( $INTEGRATED_GRAPHICS == 1 ));
then
    RESERVED_MEM=$((RESERVED_MEM + 10000))
    if (( $RESERVED_MEM >= $TOTAL_MEM ));
    then
        RESERVED_MEM=TOTAL_MEM
    fi
fi
STRESS_MEM=$((TOTAL_MEM - RESERVED_MEM))
if (( $STRESS_MEM <= 0 ));
then
    STRESS_MEM=1
fi
CPU_CORES=`nproc`
STRESS_MEM_PER_WORKER=$(((STRESS_MEM / CPU_CORES) + 1))

if [ ! -e "`eval echo ${STRESS_NG_PATH//>}`" ];
then
    bash s76-setup-stress-ng.sh
fi
if ! command -v gnome-terminal &> /dev/null
then
    sudo apt-get update
    sudo apt install -y gnome-terminal
fi

if [ ! -e /etc/sudoers.d/stress-ng ];
then
    echo "$USER ALL = NOPASSWD: $STRESS_NG_PATH" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/stress-ng' &>/dev/null)
fi

gnome-terminal --name=s76-stress-ng --title=System76-stress-ng --geometry=868x25+-26+9 -- bash -c "while true; do sudo $STRESS_NG_PATH $OPTIONS_STR --vm-bytes ${STRESS_MEM_PER_WORKER}M --timeout $((60 + ($RANDOM % 541))); done; exec bash"
