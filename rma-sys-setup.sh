#!/usr/bin/env bash

VGA_STR=`lspci | grep VGA`
REBOOT=0

Help()
{
    echo ""
    echo "Options:"
    echo "-h        Display this message and exit."
    echo "-s        Sets the hostname"
    echo "-r        Reboot after installing things."
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


while getopts ":hs:t" option; do
    case $option in
        h) # help text
            Help
            exit;;
        s) # Hostname
            Host $OPTARG;;
        r) # Reboot
            REBOOT=1;;
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

# If trubble-checklist is installed, remove it
if command -v trubble-checklist &> /dev/null
    then
        sudo apt remove trubble-checklist -y
fi

install() {
    sudo apt update
    sudo apt dist-upgrade -y
    
    # If the system uses an Nvidia GPU, check if the driver is installed. 
    if [[ $VGA_STR == *"NVIDIA"* ]]; then
        if command -v nvidia-smi &> /dev/null
            then echo "" &> /dev/null
        else 
            clear
            echo "The NVIDIA driver is not installed. Please re-image or install the appropriate packages"
            exit
        fi
    fi

    RMA_UTILS="ls $USER/Documents/rma-utils &> /dev/null"
    cd ~/Documents
    if ! [ -d $RMA_UTILS ]; then
        git clone https://github.com/jklgrasso/rma-utils
    fi

    if $REBOOT=1; then
        reboot
    else
        clear
        echo "Done setting up."
    fi

    ./s76-pts-setup.sh
}

install