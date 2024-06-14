#!/usr/bin/env bash

Help()
{
    echo ""
    echo "Options:"
    echo "-h        Display this message and exit."
    echo "-s        Sets the hostname"
}

#sets the hostname if desired
Host()
{
    echo "127.0.0.1     ${1}.localdomain $1" | sudo tee -a /etc/hosts
    sudo hostnamectl set-hostname $1
    clear
    hostname
    sleep 10
}

TRUBBLE=0

while getopts ":hs:t" option; do
    case $option in
        h) # help text
            Help
            exit;;
        s) # Hostname
            Host $OPTARG;;
        *) # bad option
            Help 1>&2
            exit 1;;
    esac
done

#sets settings for suspend, display timeout, and idle sleep
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.desktop.session idle-delay 0  

#remove trubble checklist and prepare to ship from oem, set timezone, update upgrade reboot
sudo apt remove trubble-checklist -y
sudo rm -rf /usr/local/bin/*-preparetoship*
sudo timedatectl set-timezone America/Denver
sudo apt update
sudo apt full-upgrade -y && reboot
