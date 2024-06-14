#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
BUILD_GPU_BURN=0
if (($# == 0));
then
    MINUTES=60
else
    MINUTES=$1
fi
if (($MINUTES < 10));
then
    MINUTES=10
fi

SECONDS=$(($MINUTES * 60))

gnome-terminal --geometry=921x334+-26+102 --name=s76-gpu-burn --title=System76-gpu-burn -- bash -c "PATH=$PATH:$SCRIPT_PATH/bin LD_LIBRARY_PATH=$SCRIPT_PATH/lib gpu_burn -tc $SECONDS"
gnome-terminal --geometry=921x547+-26+459 --name=s76-nvidia-smi --title=System76-nvidia-smi -- watch -n 1 nvidia-smi
until pgrep -x "gpu_burn" &>/dev/null
do
    sleep 30
done
while pgrep -x "gpu_burn" &>/dev/null
do
    sleep 60
done
kill $(ps -Af | grep watch | grep nvidia-smi | awk '{print $2}')