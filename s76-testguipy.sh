#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
USER_HOME=$HOME

if [ ! -e test_gui ]; then
    tar xvf test_gui.tar.xz
fi

sudo PATH=$SCRIPT_PATH/bin:$PATH LD_LIBRARY_PATH=$SCRIPT_PATH/lib PYTHONPATH=$USER_HOME/.local/lib/python3.10/site-packages ./test_gui
