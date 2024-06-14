#!/bin/bash

while IFS= read -r line
do
    # Echo each ubuntu kernel config option into the .config file
    if [ -e $line ]
    then
        sudo rm -rvf $line
    fi
done < cleanup.txt

echo "Set idle-delay to 300 seconds"
gsettings set org.gnome.desktop.session idle-delay 300
echo "turn on idle suspend"
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "suspend"