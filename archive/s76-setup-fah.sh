#!/bin/bash
if [ -e temp ];
then
    rm -rvf temp
fi
if [ ! -e fahclient_7.4.4_amd64.deb ];
then
    wget https://download.foldingathome.org/releases/public/release/fahclient/debian-testing-64bit/v7.4/fahclient_7.4.4_amd64.deb -O temp
    mv temp fahclient_7.4.4_amd64.deb
fi
if [ ! -e fahcontrol_7.4.4-1_all.deb ];
then
    wget https://download.foldingathome.org/releases/public/release/fahcontrol/debian-testing-64bit/v7.4/fahcontrol_7.4.4-1_all.deb -O temp
    mv temp fahcontrol_7.4.4-1_all.deb
fi
if [ ! -e fahviewer_7.4.4_amd64.deb ];
then
    wget https://download.foldingathome.org/releases/public/release/fahviewer/debian-testing-64bit/v7.4/fahviewer_7.4.4_amd64.deb -O temp
    mv temp fahviewer_7.4.4_amd64.deb
fi
sudo dpkg -i --force-depends fahclient_7.4.4_amd64.deb
sudo dpkg -i --force-depends fahcontrol_7.4.4-1_all.deb
sudo dpkg -i --force-depends fahviewer_7.4.4_amd64.deb
