#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
: ${BUILD_GPU_BURN=0}
if [ $BUILD_GPU_BURN -gt 0 ]
then
    INSTALLED_CUDA=0

    if ! command -v git &> /dev/null
    then
        sudo apt update
        sudo apt install -y git
    fi
    if ! command -v gnome-terminal &> /dev/null
    then
        sudo apt update
        sudo apt install -y gnome-terminal
    fi

    cd "$HOME"
    if [ ! -e /usr/bin/nvcc ];
    then
        sudo apt -y install nvidia-cuda-toolkit
        INSTALLED_CUDA=1
    fi
    if [ ! -e gpu-burn ];
    then
        git clone https://github.com/wilicc/gpu-burn.git
    fi
    cd gpu-burn
    git reset --hard HEAD
    git fetch --all
    git pull
    make CUDAPATH=/usr 2>/dev/null
    cp -f gpu_burn $SCRIPT_PATH/bin
    cp -f compare.ptx $SCRIPT_PATH/bin
    if (($INSTALLED_CUDA == 1));
    then
        reboot
    fi
fi