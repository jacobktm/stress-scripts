#!/usr/bin/env bash

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

rsync -avz --delete --filter='merge rsync-filter.txt' -e ssh ./ system76@10.17.89.69:./user/Documents/stress-scripts/
ssh system76@10.17.89.69 "cd user; tar -c -I 'xz -9 -T8' -f stress-scripts.tar.xz Documents .local .ssh"
ssh -t system76@10.17.89.69 "sudo rm -rvf /opt/fileserv/files/stress-scripts.tar.xz.old; sudo mv /opt/fileserv/files/stress-scripts.tar.xz /opt/fileserv/files/stress-scripts.tar.xz.old; sudo mv user/stress-scripts.tar.xz /opt/fileserv/files"