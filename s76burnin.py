#!/usr/bin/python3
""" System76 assembly burn in test script """

from argparse import ArgumentParser
from os import environ, getlogin
from os.path import realpath, dirname
from subprocess import run, PIPE, CalledProcessError, getoutput
from threading import Thread
from time import sleep, time
from datetime import datetime
from s76utils import CommandUtils

def main():
    """
    Main function for the System76 assembly burn-in test script.
    
    Command-line Arguments:
    -c, --config: Use a specific stress-ng configuration file.
    -i, --integrated: Use integrated graphics for testing.
    -s, --skip: Skip the GPU stress tests.
    -u, --unigine: Use the Unigine engine for testing.
    
    Workflow:
    1. Initializes argument parsing and handles command-line arguments.
    2. Sets up environment variables and paths.
    3. Executes a series of tests and utility scripts, including:
        - s76-journalctl.sh
        - s76-disable-suspend.sh
        - s76-htop.sh
        - s76-gpu-burn.sh (conditional)
        - s76-unigine (conditional)
    4. Waits for certain processes to start and finish.
    5. Cleans up by killing specific windows and processes.
    
    Note:
    - Requires root privileges for certain operations.
    - Dependent on external scripts and utilities.
    """
    parser = ArgumentParser(description="Script description.")
    parser.add_argument("-i", "--integrated", action="store_true", help="Use integrated graphics.")
    parser.add_argument("-s", "--skip", action="store_true", help="Skip the GPU stress tests.")
    parser.add_argument("-l", "--skipllvm", action="store_true", help="Skip llvm stress test.")
    parser.add_argument("-u", "--unigine", action="store_true", help="Use Unigine.")

    stressng_count = 5
    run_time_minutes = '60'

    cmd_utils = CommandUtils()
    args = parser.parse_args()

    cmd_utils.run_command(["clear"], sudo=True)
    # Prompt for order number and set a default if blank
    onum = input("Enter order number: ")
    onum = onum if onum.strip() else "RMA"

    # Prompt for build number and set a default if blank
    bnum = input("Enter build number: ")
    bnum = bnum if bnum.strip() else "RMA"

    # Prompt for serial number and set a default if blank
    serialnum = input("Enter serial number: ")
    serialnum = serialnum if serialnum.strip() else datetime.now().strftime('%y%m%d%H%M%S')
    cmd_utils.run_command(['clear'])
    print("Note: total test runtime will be greater than the runtime entered.")
    print("      Memtester runs first for as long as is needed.")
    rt_input = input(f"Enter burn-in test runtime in minutes ({run_time_minutes}): ")
    if not rt_input or not rt_input.isnumeric():
        rt_input = run_time_minutes
    cmd_utils.run_command(['clear'])
    if int(rt_input) < 10:
        rt_input = '10'
    stressng_cmd = ["./s76-stress.sh", "-b", "-t", rt_input]

    if int(rt_input) < 30:
        stressng_cmd.append("-l")

    igfx = False
    if args.integrated:
        igfx = True

    cmd_utils.run_command(["clear"])

    script_path = dirname(realpath(__file__))
    local_user = getlogin()

    # Update PATH
    if script_path not in environ["PATH"]:
        environ["PATH"] = f"{script_path}/bin:{environ.get('PATH', '')}"

    # Update LD_LIBRARY_PATH
    ld_library_path = environ.get("LD_LIBRARY_PATH", "")
    if script_path not in ld_library_path:
        environ["LD_LIBRARY_PATH"] = f"{script_path}/lib:{ld_library_path}"

    env_vars = {
        "LOCAL_USER": local_user
    }
    cmd_utils.run_in_background(["./s76-journalctl.sh",
                                 "-s", serialnum],
                                sudo=True,
                                preserve_env=True,
                                env_vars=env_vars)
    cmd_utils.run_command('xdotool windowsize $(xdotool getactivewindow) 100% 100%', shell=True)
    env_vars = {
        "PATH": f"{environ['PATH']}:{script_path}/bin",
        "LD_LIBRARY_PATH": f"{script_path}/lib"
    }
    cmd_utils.run_in_background(["./s76-disable-suspend.sh"], env_vars=env_vars)
    if not args.skip:
        vga_str = getoutput('lspci | grep VGA')
        if 'NVIDIA' not in vga_str and 'Radeon' not in vga_str:
            igfx = True

        if 'NVIDIA' in vga_str and not igfx and not args.unigine:
            cmd_utils.run_in_background(["./s76-gpu-burn.sh", rt_input])

        if args.unigine or 'NVIDIA' not in vga_str:
            cmd_utils.run_command([f"./s76-unigine-valley.sh", "-b"])

    env_vars = {
        "LOCAL_USER": local_user
    }
    cmd_utils.run_in_background(["./s76-testpy.sh", "-b", "-s", serialnum],
                                sudo=True,
                                preserve_env=True,
                                env_vars=env_vars)
    if igfx:
        stressng_cmd.append("-i")
    
    if args.skipllvm and "-l" not in stressng_cmd:
        stressng_cmd.append("-l")

    # Wait for 'stress-ng' to start
    cmd_utils.run_command(stressng_cmd)
    while not cmd_utils.find_processes("stress-ng"):
        sleep(15)

    while cmd_utils.find_processes("stress-ng"):
        sleep(60)

    # Let system settle before benchmarking
    #sleep(1800)

    #env_vars = {
    #    "LOCAL_USER": local_user
    #}

    # Benchmarks coming soon
    #run_command(["./s76-kernel-benchmark.sh"],
    #            sudo=True,
    #            preserve_env=True,
    #            env_vars=env_vars)

    for pid in cmd_utils.find_processes("s76-journal", exact=False):
        cmd_utils.run_command(["kill", str(pid)], sudo=True)
    for pid in cmd_utils.find_processes("s76-disable", exact=False):
        cmd_utils.run_command(["kill", "-9", str(pid)], sudo=True)

    env_vars = {
        "LOCAL_USER": local_user,
    }
    cmd_utils.run_command(["./s76-check.sh", "-o", onum, "-b", bnum, "-s", serialnum],
                          env_vars=env_vars)

if __name__ == "__main__":
    main()
