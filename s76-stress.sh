#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
RUN_TIME=60
BURN_IN_TEST=0
SKIP_LLVM=0
INTEGRATED_GRAPHICS=""

Help()
{
    echo "Usage: s76-stress.sh [options]"
    echo ""
    echo "Options:"
    echo "-b        Burn in test."
    echo "-t        Burn in test time in seconds."
    echo "-i        Using integrated graphics."
    echo "-h        Display this message and exit."
}

while getopts ":blit:h" option; do
    case $option in
        b) # Burn in - <RUN_TIME> minutes
            BURN_IN_TEST=1;;
        l) # Skip llvm stress test
            SKIP_LLVM=1;;
        i) # pass along integrated graphics switch
            INTEGRATED_GRAPHICS=" -i";;
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

gnome-terminal --name=s76-stress --title=System76-stress --geometry=868x25+-26+9 -- bash -c "
RUN_LOOP=true
START_TIME=0
STRESS_NG_RUN_TIME=3600
RUN_TIME_SECONDS=$((RUN_TIME * 60))
if [ $BURN_IN_TEST -gt 0 ] && [ $SKIP_LLVM -gt 0 ]; then
    STRESS_NG_RUN_TIME=\"\$RUN_TIME_SECONDS\"
fi
ctrl_c() {
    RUN_LOOP=false
}
BURN_IN=\"\"
if [ $SKIP_LLVM -eq 0 ]; then
    if [ $BURN_IN_TEST -gt 0 ]; then
        LLVM_RUN_TIME=\$((RUN_TIME_SECONDS / 2))
        BURN_IN=\" -t \$LLVM_RUN_TIME\"
        START_TIME=\$(date +%s)
    fi
fi
trap ctrl_c INT TERM EXIT
while \$RUN_LOOP; do
    if [ $SKIP_LLVM -eq 0 ]; then
        ./s76-llvm-stress.sh\${BURN_IN}
        if ! \$RUN_LOOP; then
            break
        fi
        if [ $BURN_IN_TEST -gt 0 ]; then
            CURRENT=\$(date +%s)
            LLVM_RUN=\$((CURRENT-START_TIME))
            STRESS_NG_RUN_TIME=\$((RUN_TIME_SECONDS-LLVM_RUN))
        fi
    fi
    ./s76-stress-ng.sh -t \${STRESS_NG_RUN_TIME}${INTEGRATED_GRAPHICS}
    if [ $BURN_IN_TEST -gt 0 ]; then
        break
    fi
done"