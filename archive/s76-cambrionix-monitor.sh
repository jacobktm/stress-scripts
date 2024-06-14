#!/bin/bash

if ! command -v screen &> /dev/null
then
    sudo apt-get update
    sudo apt install -y screen
fi

gnome-terminal --geometry=921x547+-26+102 --name=s76-Cambrionix-Monitor --title=System76-Cambrionix-Monitor -- sudo screen /dev/ttyACM0 115200