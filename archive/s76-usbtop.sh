#!/bin/bash

if ! command -v usbtop &> /dev/null
then
    sudo apt-get update

    USBTOP_IN_APT=`apt-cache search usbtop | awk '{ print $1 }' | grep -c usbtop`

    if (( $USBTOP_IN_APT >= 1 ));
    then
        sudo apt install -y usbtop
    fi

    if (( $USBTOP_IN_APT == 0 ));
    then
        sudo apt install -y cmake git libboost-dev libpcap-dev libboost-thread-dev libboost-system-dev
        cd /home/${USER}
        git clone https://github.com/aguinet/usbtop.git
        cd usbtop
        mkdir _build
        cd _build
        cmake -DCMAKE_BUILD_TYPE=Release ..
        make
        sudo make install
    fi
fi

sudo modprobe usbmon

gnome-terminal --geometry=921x547+-26+459 --name=s76-usbtop --title=System76-usbtop -- sudo usbtop --bus usbmon6