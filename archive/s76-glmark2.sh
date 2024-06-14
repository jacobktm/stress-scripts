#!/bin/bash

unknown_count=0

if ! command -v glmark2 &>/dev/null
then
    until sudo apt update
    do
        sleep 30
    done
    sudo apt install -y glmark2
fi

if ! command -v gnome-terminal &>/dev/null
then
    until sudo apt update
    do
        sleep 30
    done
    sudo apt install -y gnome-terminal
fi

# Function to get GPU utilization
get_gpu_utilization() {
    highest_utilization=0

    # Check for AMD GPUs
    for gpu in /sys/class/drm/card*/device/gpu_busy_percent;
    do
        if [ -f "$gpu" ];
        then
            utilization=$(cat $gpu)
            if (( utilization > highest_utilization ));
            then
                highest_utilization=$utilization
            fi
        fi
    done

    # Check for NVIDIA GPUs
    if command -v nvidia-smi &>/dev/null;
    then
        utilization=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | sort -n | tail -n 1 2>/dev/null)
        ret_val=$?
        if [ $ret_val -eq 0 ] && (( utilization > highest_utilization ));
        then
            highest_utilization=$utilization
        fi
    fi

    echo $highest_utilization
}

utilization_reached=0

# Main loop
while true;
do
    min_utilization=100
    utilization_avg=0
    utilization=0

    # Check GPU utilization for 10 seconds
    for i in {1..10};
    do
        cur_utilization=$(get_gpu_utilization)
        utilization=$((utilization + cur_utilization))
        sleep 1
    done
    utilization_avg=$((utilization / 10))
    if [ $utilization_avg -eq 0 ];
    then
        if [ $unknown_count -lt 5 ];
        then
            unknown_count=$((unknown_count + 1))
        else
            utilization_avg=100
        fi
    fi
    echo $utilization_avg
    # If minimum utilization is below 98%, spawn a glmark2 terminal
    if (( $utilization_avg < 94 ));
    then
        gnome-terminal --geometry=921x547+-26+459 --name=s76-glmark2 --title=System76-glmark2 -- bash -c glmark2 --run-forever
        utilization_reached=0
    else
        if [ $utilization_reached -lt 3 ];
        then
            utilization_reached=$((utilization_reached + 1))
        else
            exit
        fi
    fi
done