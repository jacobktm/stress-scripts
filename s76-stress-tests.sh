#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
LOCAL_USER=$USER
SKIP_GPU_TEST=0
DO_NVIDIA_CHECK=1
USE_UNIGINE=0
USE_GPU_BURN=0
USE_STRESS_NG=0
MINUTES=1440
UNAME_R=`uname -r`
INTEGRATED_GRAPHICS=0
USE_INTEGRATED_GRAPHICS=""
VGA_STR=`lspci | grep VGA`
CONFIG_FILE="default.conf"
USE_RVS=0

if [ $(echo $PATH | grep -c $SCRIPT_PATH) -eq 0 ]; then
    echo PATH=$SCRIPT_PATH/bin:$PATH >> $HOME/.bashrc
    PATH=$SCRIPT_PATH/bin:$PATH
fi

Help()
{
    echo "Usage: s76-stress-tests.sh [options]"
    echo ""
    echo "options:"
    echo "-h        Display this message and exit."
    echo "-c F      Use stress-ng conf file F."
    echo "-i        Use integrated graphics."
    echo "-n        Use stress-ng instead of stress."
    echo "-s        Skip the GPU stress tests."
    echo "-t MM     Time to run gpu_burn in minutes."
    echo "-u        Skip the NVIDIA check and just"
    echo "          run Unigine"
}

while getopts ":c:hinst:uv" option; do
   case $option in
        c) # Use specified stress-ng conf file
            CONFIG_FILE=$OPTARG;;
        h) # help text
            Help
            exit;;
        i) # using integrated graphics
            INTEGRATED_GRAPHICS=1;;
        n) # Use stress-ng instead of stress
	        USE_STRESS_NG=1;;
        s) # skip GPU stress tests
            SKIP_GPU_TEST=1;;
        t) # time for gpu-burn in minutes
            MINUTES=$OPTARG;;
        u) # use unigine 
            DO_NVIDIA_CHECK=0
            USE_UNIGINE=1;;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
	        Help 1>&2 
            exit 1;;
   esac
done

sudo bash -c "export PATH=$PATH:$SCRIPT_PATH/bin; LD_LIBRARY_PATH=$SCRIPT_PATH/lib screen -d -m bash s76-disable-suspend.sh"
sudo bash -c "export PATH=${PATH}:${SCRIPT_PATH}/bin; LD_LIBRARY_PATH=${SCRIPT_PATH}/lib screen -d -m bash -c \"LOCAL_USER=$USER ./s76-journalctl.sh\""

if [ $SKIP_GPU_TEST -eq 0 ];
then
    if [[ $UNAME_R == *"5.4.0-"* ]];
    then
        USE_UNIGINE=1
        DO_NVIDIA_CHECK=0
        USE_GPU_BURN=0
    fi
    if [ $DO_NVIDIA_CHECK -eq 1 ];
    then
        if [ $(lspci | grep -c NVIDIA) -gt 0 ];
        then
            USE_GPU_BURN=1
        fi
    fi

    if [ $USE_GPU_BURN -eq 1 ];
    then
        if [ $MINUTES -le 59 ];
        then
            MINUTES=60
        fi
        bash s76-gpu-burn.sh $MINUTES &
    fi

    if [[ $VGA_STR == *"Radeon"* ]]; then
        USE_RVS=1
    fi 
    if [ $USE_RVS -eq 1 ]; then
    # add minutes?
        bash s76-rvs-setup.sh
    fi

    if [[ ! $VGA_STR == *"NVIDIA"* ]] && [[ ! $VGA_STR == *"Radeon"* ]];
    then
        INTEGRATED_GRAPHICS=1
    fi
    if [ $USE_UNIGINE -eq 1 ];
    then
        bash s76-unigine-valley.sh
    fi

fi

if [ $INTEGRATED_GRAPHICS -eq 1 ];
then
    USE_INTEGRATED_GRAPHICS=" -i"
fi
bash s76-testguipy.sh &
bash s76-stress.sh${USE_INTEGRATED_GRAPHICS}
