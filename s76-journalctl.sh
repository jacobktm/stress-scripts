#!/bin/bash

Help()
{
    echo "Usage: s76-journalctl.sh <time> [options]"
    echo ""
    echo "options:"
    echo "-h        Display this message and exit."
    echo "-s        Serial Number."
}
SINCE=$(date "+%Y-%m-%d %H:%M:%S")
SERIAL_NUM=""
SEEN=0

while getopts ":hs:" option; do
   case $option in
        h) # help text
            Help
            exit;;
        s) # Serial Num
            SERIAL_NUM="_$OPTARG";;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
	        Help 1>&2
            exit 1;;
   esac
done

cleanup() {
    echo "Cleaning up temporary files..."
    rm -f "$temp_output"
    rm -f "$temp_journal"
    if [ ! -s "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log" ]; then
        rm -f "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
    fi
    exit 0
}

trap cleanup INT TERM EXIT

if [ -f "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log" ]; then
    rm -f "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
fi

# Temporary file to store new lines.
temp_output=$(mktemp)
temp_journal=$(mktemp)

while true; do
    # Fetch the entire journal since the given timestamp.
    sudo journalctl --since="$SINCE" > "$temp_journal"

    grep -Ef PATTERNS "$temp_journal" | grep -vEf IGNORE_PATTERNS > "$temp_output"

    # Update SINCE to now, so the next iteration will pick up logs from this moment onward.
    SINCE=$(date +'%Y-%m-%d %H:%M:%S')

    # Process the new lines.
    while IFS= read -r line; do
        if [ -f "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log" ]; then
            SEEN=$(grep -c "$line" "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log")
        fi
        if [ $SEEN -gt 0 ]; then
            continue
        fi

        timestamp=$(echo "$line" | awk '{print $1, $2, $3}')

        if [[ $line == *"[ cut here ]"* ]]; then
            block=$(awk -v start_pat="${timestamp}.*\\[ cut here \\]" \
                -v stop_pat="${timestamp}.*\\[ end trace [0-9a-fA-F]+ \\]" \
                'BEGIN{flag=0} $0 ~ start_pat{flag=1} flag && $0 ~ stop_pat{print; flag=0; exit} flag' "$temp_journal")
            if [[ -n $block ]]; then
                echo "$block" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            else
                echo "$line" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            fi
        elif [[ $line == *"invoked oom-killer"* ]]; then
            block=$(awk -v start_pat="${timestamp}.*invoked oom-killer" \
                -v stop_pat="${timestamp}.*Out of memory" \
                'BEGIN{flag=0} $0 ~ start_pat{flag=1} flag && $0 ~ stop_pat{print; flag=0; exit} flag' "$temp_journal")
            if [[ -n $block ]]; then
                echo "$block" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            else
                echo "$line" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            fi
        elif [[ $line == *"Oops:"* ]]; then
            block=$(awk -v start_pat="${timestamp}.*Oops:" \
                -v stop_pat="${timestamp}.*</TASK>" \
                'BEGIN{flag=0} $0 ~ start_pat{flag=1} flag && $0 ~ stop_pat{print; flag=0; exit} flag' "$temp_journal")
            if [[ -n $block ]]; then
                echo "$block" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            else
                echo "$line" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            fi
        elif [[ $line == *"Modules linked in:"* ]]; then
            block=$(awk -v start_pat="${timestamp}.*Modules linked in:" \
                -v stop_pat="${timestamp}.*</TASK>" \
                'BEGIN{flag=0} $0 ~ start_pat{flag=1} flag && $0 ~ stop_pat{print; flag=0; exit} flag' "$temp_journal")
            if [[ -n $block ]]; then
                echo "$block" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            else
                echo "$line" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            fi
        elif [[ $line == *"segfault"* ]]; then
            block=$(awk -v start_pat="${timestamp}.*segfault" \
                -v stop_pat="${timestamp}.*Code:" \
                'BEGIN{flag=0} $0 ~ start_pat{flag=1} flag && $0 ~ stop_pat{print; flag=0; exit} flag' "$temp_journal")
            if [[ -n $block ]]; then
                echo "$block" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            else
                echo "$line" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            fi
        elif [[ $line == *"GPU reset begin"* ]]; then
            block=$(awk -v start_pat="${timestamp}.*GPU reset begin" \
                -v stop_pat="${timestamp}.*amdgpu: soft reset" \
                'BEGIN{flag=0} $0 ~ start_pat{flag=1} flag && $0 ~ stop_pat{print; flag=0; exit} flag' "$temp_journal")
            if [[ -n $block ]]; then
                echo "$block" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            else
                echo "$line" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
            fi
        else
            echo "$line" >> "/home/${LOCAL_USER}/Desktop/journalctl${SERIAL_NUM}.log"
        fi
    done < "$temp_output"
    sleep 5
done