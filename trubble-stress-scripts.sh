#!/usr/bin/env bash

download_files() {
    base_url="https://github.com/jacobktm/work-scripts/raw/main/"
    for file in "$@"; do
        if [ -e "$file" ]; then
            rm "$file"
        fi
        wget "${base_url}${file}"
        if [ ! "$file" == "bash_aliases" ]; then
            echo "chmod +x $file"
            chmod +x "$file"
        fi
    done
}

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

download_files bash_aliases install.sh prepare.sh terminal.sh system76-ppa.sh mainline.sh suspend.sh resume-hook.sh apt-proxy add-local-bin.sh add-local-bin.desktop
sed -i "s|\./install\.sh|/home/oem/Documents/stress-scripts/install.sh|g" bash_aliases
sed -i "s|\./terminal\.sh|/home/oem/Documents/stress-scripts/terminal.sh|g" bash_aliases
sed -i "s|\./install\.sh|/home/oem/Documents/stress-scripts/install.sh|g" suspend.sh
sed -i "s|\./install\.sh|/home/oem/Documents/stress-scripts/install.sh|g" terminal.sh
sed -i "s|\./install\.sh|/home/oem/Documents/stress-scripts/install.sh|g" mainline.sh
sed -i "s|\./count|/home/oem/Documents/stress-scripts/count|g" suspend.sh
sed -i "s|\./resume-hook\.sh|/home/oem/Documents/stress-scripts/resume-hook.sh|g" suspend.sh

rsync -avz --delete --filter='merge rsync-filter.txt' -e ssh ./ system76@10.17.89.69:./user/Documents/stress-scripts/

ssh system76@10.17.89.69 << 'EOF'
cd user
if [ -e stress-scripts.tar.xz ]; then
    rm -rvf stress-scripts.tar.xz
fi
mv Documents/stress-scripts/bash_aliases ./.bash_aliases
mkdir -p .local/bin
mv Documents/stress-scripts/suspend.sh .local/bin/sustest
mv Documents/stress-scripts/mainline.sh .local/bin/setup-mainline
mv Documents/stress-scripts/system76-ppa.sh .local/bin/system76-ppa
mv Documents/stress-scripts/apt-proxy .local/bin/apt-proxy
mv Documents/stress-scripts/add-local-bin.sh .local/bin/add-local-bin.sh
mkdir -p .config/autostart
mv Documents/stress-scripts/add-local-bin.desktop .config/autostart/            
if [ -d Documents/stress-scripts/.git ]; then
    rm -rvf Documents/stress-scripts/.git*
fi
tar -c -I 'xz -9 -T8' -f stress-scripts.tar.xz .bash_aliases Documents .local .ssh .config
EOF

ssh -t system76@10.17.89.69 "sudo rm -rvf /opt/fileserv/files/stress-scripts.tar.xz.old; sudo mv /opt/fileserv/files/stress-scripts.tar.xz /opt/fileserv/files/stress-scripts.tar.xz.old; sudo mv user/stress-scripts.tar.xz /opt/fileserv/files"

rm -rvf bash_aliases install.sh prepare.sh terminal.sh system76-ppa.sh mainline.sh suspend.sh resume-hook.sh apt-proxy add-local-bin.sh add-local-bin.desktop