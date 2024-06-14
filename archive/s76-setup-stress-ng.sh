#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
cd $HOME
: ${BUILD_STRESS_NG:=0}
if [ $BUILD_STRESS_NG -gt 0 ];
then
    if [ ! -d stress-ng ];
    then
        git clone https://github.com/ColinIanKing/stress-ng.git
    fi
    cd stress-ng
    git reset --hard HEAD
    git fetch --all
    git pull
    sudo apt update
    sudo apt install -y libaio-dev libapparmor-dev libattr1-dev libbsd-dev libcap-dev libgcrypt-dev libipsec-mb-dev libjpeg-dev libjudy-dev libkeyutils-dev libsctp-dev libatomic1 libglvnd-dev libgbm-dev zlib1g-dev libkmod-dev libxxhash-dev
    make -j `nproc`
    cp -f stress-ng $SCRIPT_PATH/bin
fi