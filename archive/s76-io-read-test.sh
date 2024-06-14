#!/bin/bash

BLOCK_SIZE="64K"
COUNT=6553700
DEV_PATH=`pwd`
TEMPFILE="${DEV_PATH}/scratch.temp"
INST_COUNT=0

PREV_INST=`ps -A | grep -c ' dd'`
if (( $PREV_INST > 0 ));
then
    sudo pkill bash
    sudo pkill dd
fi

if [ ! -e $TEMPFILE ];
then
    dd if=/dev/zero of=$TEMPFILE bs=$BLOCK_SIZE count=$COUNT
    sync
fi

while (( $INST_COUNT < 3 ));
do
    (while true; do dd if=$TEMPFILE of=/dev/null bs=$BLOCK_SIZE count=$COUNT; done) &
    INST_COUNT=$((INST_COUNT + 1))
done