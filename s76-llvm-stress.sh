#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
RUN_TIME=3600
START_TIME=0
SINGLE_RUN=0
RUN_LOOP=true

download_llvm() {
    RESPONSE=$(curl -I -s -o /dev/null -w "%{http_code}" "http://10.17.89.69:5000/download/llvm-project-main.zip")
    LLVM_URL="https://github.com/llvm/llvm-project/archive/refs/heads/main.zip"
    if [ "$RESPONSE" -eq 200 ]; then
        LLVM_URL="http://10.17.89.69:5000/download/llvm-project-main.zip"
    fi
    pushd ~/Documents
        if wget "${LLVM_URL}" -O temp; then
            mv temp llvm-project.zip
        fi
    popd
}

ctrl_c() {
    RUN_LOOP=false
}

Help()
{
    echo "Usage: s76-llvm-stress.sh [options]"
    echo ""
    echo "Options:"
    echo "-t        Burn in test time in seconds."
    echo "-h        Display this message and exit."
}

while getopts ":t:h" option; do
    case $option in
        t) # Set RUN_TIME
            RUN_TIME=$OPTARG;;
        h) # help text
            Help
            exit;;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
            Help 1>&2
            exit 1;;
    esac
done

if [ ! -e ~/Documents/llvm-project.zip ]; then
    download_llvm
fi
if [ -d ~/Documents/llvm-project-main ]; then
    pushd ~/Documents
        rm -rvf llvm-project-main
    popd
fi
pushd ~/Documents
    unzip llvm-project.zip
popd

trap ctrl_c INT TERM EXIT

pushd ~/Documents/llvm-project-main
    if [ $(echo $PATH | grep -c $SCRIPT_PATH) -eq 0 ]; then
        export PATH="${SCRIPT_PATH}/bin:$PATH"
    fi
    export LD_LIBRARY_PATH="${SCRIPT_PATH}/lib"
    START_TIME=$(date +%s)
    while $RUN_LOOP; do
        cmake -S llvm -B build -DCMAKE_BUILD_TYPE=Release -G Ninja
        if ! $RUN_LOOP; then
            break
        fi
        ninja -C build check-llvm
        rm -rvf build
        CURRENT=$(date +%s)
        if [ $SINGLE_RUN -eq 0 ]; then
            SINGLE_RUN=$((CURRENT-START_TIME))
        fi
        TIME_SO_FAR=$((CURRENT-START_TIME))
        TIME_LEFT=$((RUN_TIME-TIME_SO_FAR))
        if [ $SINGLE_RUN -gt $TIME_LEFT ]; then
            break
        fi
    done
popd