#!/bin/bash

BURN_IN=0

Help()
{
    echo "Usage: s76-unigine-valley.sh [options]"
    echo ""
    echo "options:"
    echo "-h        Display this message and exit."
    echo "-b        Burn in test, run until stress-ng dies"
}

while getopts ":bh" option; do
   case $option in
        b) # Use specified stress-ng conf file
            BURN_IN=1;;
        h) # help text
            Help
            exit;;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
	        Help 1>&2
            exit 1;;
   esac
done

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
VALLEY_PATH="${HOME}/Documents/Unigine_Valley-1.0/valley"
if [ ! -e "`eval echo ${VALLEY_PATH//>}`" ];
then
    bash s76-setup-unigine.sh
fi
cd ${HOME}/Documents/Unigine_Valley-1.0
XAXIS=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
YAXIS=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2)
gnome-terminal --name=s76-unigine-valley --title=System76-unigine-valley --geometry=868x25+-26+9 -- bash -c "
ctrl_c() {
    CONTINUE=0
}
CONTINUE=1
BURN_IN=$BURN_IN
JUST_STARTED=1
STRESS_NG_RUNNING=0

trap ctrl_c INT TERM EXIT

while [ \$CONTINUE -gt 0 ]; do
    if [ \$BURN_IN -gt 0 ] && [ \$JUST_STARTED -gt 0 ] && [ \$STRESS_NG_RUNNING -eq 0 ]; then
        if pgrep -x "stress-ng" &>/dev/null; then
            JUST_STARTED=0
            STRESS_NG_RUNNING=1
        fi
    fi
    if [ \$BURN_IN -gt 0 ] && [ \$JUST_STARTED -eq 0 ] && [ \$STRESS_NG_RUNNING -gt 0 ]; then
        if ! pgrep -x "stress-ng" &>/dev/null; then
            CONTINUE=0
            kill \$(pgrep -x \"valley_x64\")
        fi
    fi
    export LD_LIBRARY_PATH=./bin:./bin/x64/:\$LD_LIBRARY_PATH; ./bin/valley_x64 \
     -data_path ../ \
     -sound_app null \
     -engine_config ../data/valley_1.0.cfg \
     -system_script valley/unigine.cpp \
     -video_mode -1 \
     -extern_define PHORONIX,RELEASE \
     -video_width $XAXIS \
     -video_height $YAXIS \
     -video_fullscreen 0 \
     -video_app opengl
done"
