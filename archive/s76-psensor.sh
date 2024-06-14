#!/bin/bash

if ! command -v psensor &> /dev/null
then
    sudo apt-get update
    sudo apt install -y psensor
fi

if ! command -v screen &> /dev/null
then
    sudo apt-get update
    sudo apt install -y screen
fi

screen -d -m psensor
