"""Some utility functions
"""

import subprocess
from subprocess import PIPE, run, CalledProcessError
from threading import Thread
from os import environ
from sudomodule import SudoCommand            

class CommandUtils:
    def __init__(self):
        self.sudo_cmd = SudoCommand()

    def run_command(self, command, sudo=False, shell=False, preserve_env=False, env_vars=None):
        """
        Execute a shell command, optionally with sudo and preserving the environment.

        Parameters:
        - command (list of str or str): The command and its arguments to execute.
        - sudo_cmd (SudoCommand object, optional): An instance of the SudoCommand class
                                                   for privilege escalation.
        - sudo (bool, optional): If True, execute the command with sudo. Default is False.
        - shell (bool, optional): If True, run the command in the shell. Default is False.
        - preserve_env (bool, optional): If True, preserve the environment when using sudo
                                         (`sudo -E`). Default is False.
        - env_vars (dict, optional): A dictionary of environment variables to set for the
                                     command.

        Returns:
        - tuple: A tuple containing two elements. The first element is the command's standard
                 output as a string. The second element is either None if the command was
                 successful, or the standard error as a string if the command failed.

        Raises:
        - subprocess.CalledProcessError: Raised when the command returns a non-zero exit status.
        """
        output = None
        error = None
        try:
            if sudo:
                if env_vars:
                    env_str = ' '.join([f"export {k}={v};" for k, v in env_vars.items()])
                    self.sudo_cmd.run(["bash", "-c", f"{env_str} {' '.join(command)}"],
                                 preserve_env=preserve_env)
                else:
                    self.sudo_cmd.run(command, preserve_env=preserve_env)
            else:
                if env_vars:
                    new_env = environ.copy()
                    new_env.update(env_vars)
                else:
                    new_env = None
                completed = run(command, shell=shell, check=True,
                                stdout=PIPE, stderr=PIPE, env=new_env)
                output = completed.stdout.decode('utf-8') if completed.stdout else None
                error = completed.stderr.decode('utf-8') if completed.stderr else None
                return output.strip() if output else None, error.strip() if error else None
        except CalledProcessError as err:
            error = err.stderr.decode('utf-8') if err.stderr else None
            return None, error.strip() if error else None
        except TypeError:
            return None, "TypeError occurred. Could not decode output or error."

    def run_in_background(self, command, sudo=False, preserve_env=False, env_vars=None):
        """
        Executes a command in a separate thread, optionally with sudo and environment variables.

        This function runs a command in a separate thread so as to not block the execution of
        the script. It prints the command's standard output and standard error to the console.
        If the command fails, it catches the `subprocess.CalledProcessError` and prints the error.

        Parameters:
        - command (list of str or str): The command and its arguments to execute.
        - sudo_cmd (SudoCommand object, optional): An instance of the SudoCommand class for privilege
                                                   escalation. Defaults to None.
        - sudo (bool, optional): If True, execute the command with sudo. Defaults to False.
        - preserve_env (bool, optional): If True, preserve the environment variables when running the
                                         command. Defaults to False.
        - env_vars (dict, optional): A dictionary of environment variables to set when running the
                                     command. Defaults to None.

        Returns:
        None

        Note:
        The function starts a new thread for running the command and returns immediately.
        """
        def target():
            try:
                result = self.run_command(command, sudo=sudo, preserve_env=preserve_env,
                                          env_vars=env_vars)
                if result is not None:
                    output, error = result
                    if output:
                        print(f"Command output: {output}")
                    if error:
                        print(f"Command error: {error}")
            except CalledProcessError as err:
                return None, err.stderr.decode('utf-8').strip()

        thread = Thread(target=target)
        thread.start()

    def find_processes(self, process_name, exact=True):
        """
        Find all running processes with a given name and return their PIDs as a list.

        Parameters:
        - process_name (str): The name of the process to search for.

        Returns:
        - list of int or None: A list of PIDs corresponding to the running processes 
          with the given name. Returns None if no such process is found or an error occurs.

        Example:
        >>> find_processes("python3")
        [1234, 5678]

        Note:
        This function relies on the 'pgrep' command-line utility and may not be
        portable across all systems.
        """
        pgrep_cmd = ["pgrep"]
        if exact:
            pgrep_cmd.append("-x")
        pgrep_cmd.append(process_name)
        pids, err = self.run_command(pgrep_cmd)
        if err is None and pids:
            return list(map(int, pids.strip().split("\n")))
        else:
            return None
