#!/usr/bin/env bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

# Install Phoronix. 

# Check for dependencies and install if missing
packages=(git php-cli php-xml php-gd php-bz2 php-sqlite3 php-curl)
for package in "${packages[@]}"; do
    if ! dpkg -s "$package" &> /dev/null; then
        if DEBUG = 1; then 
            echo "Installing missing package(s): $package" >> pts-it-log.log
        fi
        sudo apt-get install -y "$package"
    fi
done

# Clone the Phoronix Test Suite repository if not already cloned
pts_dir="$HOME/phoronix-test-suite"
if [ ! -d "$pts_dir" ]; then
    git clone https://github.com/phoronix-test-suite/phoronix-test-suite.git "$pts_dir"
fi

if DEBUG = 1; then 
    echo "Cloning Phoronix Test Suite..." >> pts-it-log.log
fi

# Create alias in .bashrc if not already present
alias_line='alias pts="./phoronix-test-suite/phoronix-test-suite"'
if ! grep -q "$alias_line" "$HOME/.bashrc"; then
    
    echo "$alias_line" >> "$HOME/.bashrc"
    # Source .bashrc to make the alias immediately available
    source "$HOME/.bashrc"
fi

if DEBUG = 1; then 
    echo "Adding 'pts' alias to .bashrc" >> pts-it-log.log
fi