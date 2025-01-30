#! /usr/bin/env bash

###### NOTES ######

# 22.04 Dependencies and install guide can be found here https://github.com/ROCm/ROCmValidationSuite?tab=readme-ov-file

ROCM_RVS_PATH="/opt/rocm-6.3.2/bin"

# Install amdgpu-install. This takes a while
rocm-install(){
    echo "Installing amdgpu-install. This will take a while."

    sudo apt update -y &> /dev/null;
    sudo apt install libpci3 libpci-dev doxygen unzip cmake git libyaml-cpp-dev -y &> /dev/null;
    sudo apt install rocblas rocm-smi-lib -y &> /dev/null;

    if [ ! -e "/opt/rocm/lib/librocm_smi64.so" ]; then
        sudo dpkg -r rocm-smi-lib &> /dev/null;
        sudo apt install rocm-smi-lib -y &> /dev/null;
    fi

    sudo apt update &> /dev/null;
    sudo apt install python3-setuptools python3-wheel -y &> /dev/null;
    sudo usermod -a -G render,video $LOGNAME &> /dev/null; # Add the current user to the render and video groups
    wget https://repo.radeon.com/amdgpu-install/6.3.2/ubuntu/jammy/amdgpu-install_6.3.60302-1_all.deb &> /dev/null;
    sudo apt install ./amdgpu-install_6.3.60302-1_all.deb &> /dev/null;
    sudo apt update &> /dev/null;
    sudo apt install amdgpu-dkms rocm -y &> /dev/null

    sudo apt install rocm-validation-suite -y &> /dev/null
    echo "Installed"
}

# Check if everything above is already installed. If not, install it.
if command -v rocm-smi &> /dev/null; then
    break
else
    rocm-install
fi

#sed -i "s/$device:/$replace/g" "$file"

AMD_INTEGRATED=0
AMD_DEDICATED=0

if lspci | grep -i 'VGA' | grep -qi 'AMD'; then
    echo "Integrated AMD GPU detected"
    AMD_DEDICATED=1
elif lspci | grep -E '3D|Display' | grep -qi 'AMD'; then
    echo "Dedicated AMD GPU detected"
    AMD_INTEGRATED=1
else
    echo "No AMD GPU detected"
fi

# Get GFX version using rocminfo
ROCMINFO_PATH="/opt/rocm-6.3.2/bin/rocminfo"
GFX_VERSION=$(sudo "$ROCMINFO_PATH" | grep -m1 'gfx' | awk '{print $2}' | sed 's/gfx//')

# If detection fails, ask user for input
if [[ -z "$GFX_VERSION" ]]; then
    echo "Could not detect GFX version automatically."
    read -p "Please enter the GFX version manually: " GFX_VERSION
else
    GFX_VERSION="${GFX_VERSION:0:2}.${GFX_VERSION:2:1}.0"  # Convert to HSA format
fi
echo "Using GFX Version: $GFX_VERSION"

# Run RVS
cd $ROCM_RVS_PATH
sudo HSA_OVERRIDE_GFX_VERSION="$GFX_VERSION" ./rvs -c ../share/rocm-validation-suite/conf/gst_stress.conf