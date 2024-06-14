#!/bin/bash

Help()
{
    echo "Usage: s76-journalctl.sh <time> [options]"
    echo ""
    echo "options:"
    echo "-h        Display this message and exit."
    echo "-o        Order Number."
    echo "-b        Build Number."
    echo "-s        Serial Number."
}
SERIAL_NUM=""
ORDER_NUM=""
BUILD_NUM=""

while getopts ":hb:o:s:" option; do
   case $option in
        h) # help text
            Help
            exit;;
        o) # Order Num
            ORDER_NUM=$OPTARG;;
        b) # Build Num
            BUILD_NUM=$OPTARG;;
        s) # Serial Num
            SERIAL_NUM="_$OPTARG";;
        *) # Invalid option
            echo "Error: Invalid option" 1>&2
	        Help 1>&2
            exit 1;;
   esac
done

MESSAGE=""

print_failed() {
    gnome-terminal --maximize -- bash -c 'echo -e "$(cat ascii/testfailed.txt)"; echo -e "$(cat ascii/guillotine.txt)"; exec bash'
}

print_passed() {
    gnome-terminal --maximize -- bash -c "echo -e \"\$(cat ascii/testpassed.txt)\"; echo -e \"\$(cat ascii/surprised_pikachu.txt)\"; echo -e \"$MESSAGE\"; exec bash"
}

if [ -e "/home/$LOCAL_USER/Desktop/memtester_errors.log" ] ||
   [ -e "/home/$LOCAL_USER/Desktop/journalctl${SERIAL_NUM}.log" ]; then
    print_failed
    exit
fi
ssh system76@10.17.89.69 mkdir -p "/home/system76/burn_in_logs/${ORDER_NUM}/${BUILD_NUM}"
if [ $? -eq 0 ]; then
    scp "/home/${LOCAL_USER}/Desktop/burn-in_log${SERIAL_NUM}.txt" "system76@10.17.89.69:/home/system76/burn_in_logs/${ORDER_NUM}/${BUILD_NUM}/"
    scp -r "/home/${LOCAL_USER}/Documents/memtester/memtester_logs" "system76@10.17.89.69:/home/system76/burn_in_logs/${ORDER_NUM}/${BUILD_NUM}/"
else
    mkdir -p "/home/${LOCAL_USER}/Desktop/burn_in_logs/${ORDER_NUM}/${BUILD_NUM}"
    cp "/home/${LOCAL_USER}/Desktop/burn-in_log${SERIAL_NUM}.txt" "/home/${LOCAL_USER}/Desktop/burn_in_logs/${ORDER_NUM}/${BUILD_NUM}/"
    cp -r "/home/${LOCAL_USER}/Documents/memtester/memtester_logs" "/home/${LOCAL_USER}/Desktop/burn_in_logs/${ORDER_NUM}/${BUILD_NUM}/"
    MESSAGE="Failed to connect to Burn-in Server...\nCopied Burn-in logs to Desktop."
fi
print_passed