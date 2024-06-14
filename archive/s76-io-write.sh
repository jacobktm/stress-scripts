#!/bin/bash

DEV_LIST="b c d e f g h i j k l m n o p"
ISO_PATH='${HOME}/Downloads/pop-os_22.04_amd64_nvidia_6.iso'

if ! command -v wget &> /dev/null
then
    sudo apt-get update
    sudo apt install -y wget
fi

if [ ! -e "`eval echo ${ISO_PATH//>}`" ];
then
    pushd ${HOME}/Downloads
    wget https://pop-iso.sfo2.cdn.digitaloceanspaces.com/22.04/amd64/nvidia/6/pop-os_22.04_amd64_nvidia_6.iso
    popd
fi

if [ ! -e /etc/sudoers.d/dd ];
then
    DD_PATH=`which dd`
    echo "$USER ALL = NOPASSWD: $DD_PATH" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/dd')
fi

for char in $DEV_LIST
do
    (while true; do sudo dd if=/home/${USER}/Downloads/pop-os_22.04_amd64_nvidia_6.iso of=/dev/sd${char}; sync; done) &
done