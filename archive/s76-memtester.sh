#!/bin/bash

SERIAL_NUM=""

Help()
{
    echo "Usage: $0 [options]"
    echo ""
    echo "options:"
    echo "-h        Display this message and exit."
    echo "-s        Serial Number"
}

while getopts ":hs:" option; do
   case $option in
        h) # help text
            Help
            exit;;
        s) # Serial Number
            SERIAL_NUM="${OPTARG}_";;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
	        Help 1>&2
            exit 1;;
   esac
done

sudo echo "$(date) Running memtester"

# Directory for logs
LOG_DIR="/home/$LOCAL_USER/Documents/memtester/memtester_logs"
mkdir -p $LOG_DIR

# Total memory to test in MB
D_TO_MB=1000
if grep -q "kB" /proc/meminfo; then
    D_TO_MB=1000
else
    D_TO_MB=1000000
fi

TOTAL_MEM_KB=$(awk '/MemFree/ { print $2 }' /proc/meminfo)
TOTAL_MEM=$((TOTAL_MEM_KB / D_TO_MB))
MEM_RESERVE=$(((TOTAL_MEM / 16) + 4000))
MEM_TO_TEST=$((TOTAL_MEM - MEM_RESERVE))

# Number of threads/cores
THREADS=$(nproc)
RESERVE=$((THREADS / 8))
WORKERS=$((THREADS - RESERVE))

# Memory per thread
MEM_PER_THREAD=$((MEM_TO_TEST / WORKERS))

PIDS=()  # To keep track of memtester process IDs

# Function to handle Ctrl+C interrupt
terminate_script() {
    echo -e "\nTerminating running memtester instances..."
    for pid in "${PIDS[@]}"; do
        kill -9 $pid 2>/dev/null
    done
    exit 1
}

trap 'terminate_script' SIGINT

# Spinner function
display_spinner(){
    local spin='-\|/'
    local i=0
    while true; do
        # Count the number of still-running processes
        local count=0
        for pid in "${PIDS[@]}"; do
            if kill -0 $pid &>/dev/null; then
                count=$((count+1))
            fi
        done
        # If no processes are running, exit the spinner
        if [[ $count -eq 0 ]]; then
            return
        fi
        # Update spinner
        i=$(( (i+1) %4 ))
        printf "\r$(date) ${spin:$i:1} memtester is running ($count out of $WORKERS threads active). Please wait..."
        sleep .3
    done
}

# Start memtester instances and redirect output to log files
for i in $(seq 1 $WORKERS); do
    LOG_FILE="$LOG_DIR/memtester_log_${SERIAL_NUM}${i}.txt"
    memtester ${MEM_PER_THREAD}M 1 &> "$LOG_FILE" &
    pid=$!
    PIDS+=("$pid")
    sleep 0.1  # Short pause to ensure output order
done

# Display the spinner
display_spinner

# Wait for all memtester instances to finish
wait

clear

# Display the logs
for i in $(seq 1 $WORKERS); do
    echo "===== THREAD $i OUTPUT ====="
    if [ $(grep -c FAILURE $LOG_DIR/memtester_log_${SERIAL_NUM}${i}.txt) -gt 0 ]; then
        echo "===== THREAD $i OUTPUT =====" >> "/home/${LOCAL_USER}/Desktop/memtester_errors.log"
        echo -e $(cat "$LOG_DIR/memtester_log_${SERIAL_NUM}${i}.txt") >> "/home/${LOCAL_USER}/Desktop/memtester_errors.log"
        echo -e "\n\n" >> "/home/${LOCAL_USER}/Desktop/memtester_errors.log"
    fi
    cat "$LOG_DIR/memtester_log_${SERIAL_NUM}${i}.txt"
    echo -e "\n\n"
    sleep 1
done

echo "All tests completed."
