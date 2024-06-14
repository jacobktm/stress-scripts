#!/bin/bash

# Path to the submodule directory
STRESSMON_PATH="stressmon"

# Check if the submodule directory exists and is not empty
if [ -d "$STRESSMON_PATH" ] && [ "$(ls -A $STRESSMON_PATH)" ]; then
    # Check if the submodule is initialized and cloned
    if git submodule status $STRESSMON_PATH | grep -q '^ '; then
        echo "stressmon has already been cloned."
    else
        echo "stressmon directory exists but has not been initialized/cloned."
        git submodule update --init --recursive --checkout
    fi
else
    echo "stressmon has not been cloned."
    git submodule update --init --recursive --checkout
fi

if ! ./s76setuptestpy.py; then
    cp pip/python.tar.xz ~/
    pushd ~/
        tar xvf python.tar.xz
        rm -rvf python.tar.xz
    popd
fi