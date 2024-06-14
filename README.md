# System76 Stress Test Scripts

This repository contains a collection of Bash scripts designed to stress test various components of your system, such as CPU, GPU, and memory. There is also a Python script included that monitors hardware sensors.

## Main Stress Test Script

The main script (`s76-stress-tests.sh`) is a Bash script that orchestrates the execution of the other scripts based on the provided command-line arguments.

### Usage

```bash
s76-stress-tests.sh [options]
```

#### Options

- `-h` Display this message and exit.
- `-g` Use glmark2.
- `-c F` Use stress-ng conf file F.
- `-i` Use integrated graphics.
- `-n` Use stress-ng instead of stress.
- `-s` Skip the GPU stress tests.
- `-t HH` Time to run gpu_burn in hours.
- `-u` Skip the NVIDIA check and just run Unigine Valley

## Stress Test Scripts

This repository contains the following stress test scripts:

- `s76-testpy.sh`: This script sets up and runs the `test.py` Python script in a new terminal. The `test.py` script is used for hardware sensor monitoring and logging. Before running `test.py`, the script executes `s76-setup-testpy.sh` which installs necessary apt packages and Python packages. The new terminal with `test.py` running will appear at a specified screen position.
- `s76-setup-gpu-burn.sh`: This script sets up the environment for `s76-gpu-burn.sh`. It checks if the required dependencies (git, gnome-terminal, and NVIDIA CUDA Toolkit) are installed and if not, it installs them. It then clones the GPU-Burn repository from GitHub, fetches the latest updates, and builds the project. If CUDA was not previously installed, it also reboots the system to ensure the changes are properly applied.
- `s76-gpu-burn.sh`: This script is designed to stress test your GPU using the GPU-Burn tool. It first checks if the necessary dependencies (git, gnome-terminal, and GPU-Burn tool itself) are installed and if not, it installs them. It then runs GPU-Burn for a specified number of hours (default is 24 hours), opening two new terminals: one for the GPU-Burn tool and another to monitor GPU statistics using `nvidia-smi`.
- s76-unigine-valley.sh: This script ...
- s76-disable-suspend.sh: This script ...
- s76-htop.sh: This script ...
- s76-stress.sh: This script ...
- s76-stress-ng.sh: This script ...
- s76-glmark2.sh: This script ...

Sensor Monitoring Script
sensor_monitor.py: This Python script monitors hardware sensors and reports their readings. ...

(Note: Provide a brief description of what the script does, what sensors it monitors, etc.)

Requirements
Linux (tested on Ubuntu 18.04 and 20.04)
Bash
Python (for the sensor monitoring script)
Installation
To use these scripts, clone this repository to your local machine:

bash
Copy code
git clone https://github.com/yourusername/system76-stress-test-scripts.git
Running the Tests
To run the main stress test script with default settings, navigate to the repository directory and run:

bash
Copy code
./s76-stress-tests.sh
(Note: Add more details if necessary, such as specific options, potential issues, etc.)

