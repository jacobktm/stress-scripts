#!/bin/bash

BURN_IN=0

Help()
{
    echo "Usage: s76-unigine-superposition.sh [options]"
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

Superposition_PATH="${HOME}/Documents/Unigine_Superposition-1.1/Superposition"
if [ ! -e "`eval echo ${SUPERPOSITION_PATH//>}`" ];
then
    bash s76-setup-unigine.sh
fi
cd ${HOME}/Documents/Unigine_Superposition-1.1
XAXIS=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
YAXIS=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2)
gnome-terminal --name=s76-unigine-superposition --title=System76-unigine-superposition --geometry=868x25+-26+9 -- bash -c "
CONTINUE=1
BURN_IN=$BURN_IN
JUST_STARTED=1
STRESS_NG_RUNNING=0
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
            kill \$(pgrep -x \"superposition\")
        fi
    fi
    ./bin/superposition -sound_app openal  -system_script superposition/system_script.cpp  -data_path ../ -engine_config ../data/superposition/unigine.cfg  -video_mode -1 -project_name Superposition  -video_resizable 1  -console_command \"config_readonly 1 && world_load superposition/superposition\" -mode 2 -preset 0 -video_width $XAXIS -video_height $YAXIS -video_fullscreen 0 -shaders_quality 3 -textures_quality 2
done"