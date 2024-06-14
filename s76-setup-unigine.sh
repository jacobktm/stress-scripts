#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
VALLEY_PATH="${HOME}/Documents/Unigine_Valley-1.0/valley"
SUPERPOSITION_PATH="${HOME}/Documents/Unigine_Superposition-1.1/Superposition"
RESPONSE=$(curl -I -s -o /dev/null -w "%{http_code}" "http://10.17.89.69:5000/download/Unigine_Valley-1.0.run")
UNIGINE_URL="https://assets.unigine.com/d"
if [ "$RESPONSE" -eq 200 ];
then
    UNIGINE_URL="http://10.17.89.69:5000/download"
fi

if [ ! -e "`eval echo ${VALLEY_PATH//>}`" ];
then
    if [ -e temp ];
    then
        rm -rvf temp
    fi
    if [ ! -e ~/Documents/Unigine_Valley-1.0.run ];
    then
        pushd ~/Documents
            if wget "${UNIGINE_URL}/Unigine_Valley-1.0.run" -O temp
            then
                mv temp Unigine_Valley-1.0.run
            fi
        popd
    fi
    pushd ${HOME}/Documents
        chmod +x ./Unigine_Valley-1.0.run
        ./Unigine_Valley-1.0.run
        cp $SCRIPT_PATH/valley_1.0.cfg Unigine_Valley-1.0/data/
    popd
fi