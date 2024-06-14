#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
INTEGRATED_GRAPHICS=0
D_TO_MB=1000000
if grep -q "kB" /proc/meminfo; then
    D_TO_MB=1000
fi
RUN_TIME=1800

TOTAL_MEM_KB=$(awk '/MemAvailable/ { print $2 }' /proc/meminfo)
TOTAL_MEM=$((TOTAL_MEM_KB / D_TO_MB))
RESERVED_MEM=$((2000 + (TOTAL_MEM / 10)))

Help()
{
    echo "Usage: s76-stress-ng.sh [options]"
    echo ""
    echo "Options:"
    echo "-t        Test time in seconds."
    echo "-h        Display this message and exit."
    echo "-i        Using integrated graphics."
}

while getopts ":t:hi" option; do
    case $option in
        t) # Set RUN_TIME
            RUN_TIME=$OPTARG;;
        h) # help text
            Help
            exit;;
        i) # using integrated graphics
            INTEGRATED_GRAPHICS=1;;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
            Help 1>&2
            exit 1;;
    esac
done

if (( $INTEGRATED_GRAPHICS == 1 ));
then
    RESERVED_MEM=$((RESERVED_MEM + 10000))
    if (( $RESERVED_MEM >= $TOTAL_MEM));
    then
        RESERVED_MEM=TOTAL_MEM
    fi
fi
STRESS_MEM=$((TOTAL_MEM - RESERVED_MEM))
if (( $STRESS_MEM <= 0 ));
then
    STRESS_MEM=1
fi

if [ $(echo $PATH | grep -c $SCRIPT_PATH) -eq 0 ]; then
    export PATH="${SCRIPT_PATH}/bin:$PATH"
fi
export LD_LIBRARY_PATH="${SCRIPT_PATH}/lib"
stress-ng -c0 -m 0 --vm-bytes ${STRESS_MEM}M --timeout ${RUN_TIME}