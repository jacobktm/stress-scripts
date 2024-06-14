"""Class to encapsulate privilege escalation of shell commands with sudo
"""

from getpass import getpass, getuser
from subprocess import Popen, PIPE, check_output, CalledProcessError

class SudoCommand:
    """SudoCommand class to encapsulate privilege elevation
    """
    def __init__(self):
        self.username = getuser()
        self.password = getpass(f"[sudo] password for {self.username}: ")

    def can_sudo_without_password(self):
        """Method to test if password prompt is necessary
        """
        try:
            check_output(['sudo', '-n', 'true'])
            return True
        except CalledProcessError:
            return False

    def run(self, command, preserve_env=False):
        """Method to handle privilege elevation

        :param command: The command to run.
        :type command: list
        :param preserve_env: Whether to preserve the environment (pass `-E` to `sudo`).
        :type preserve_env: bool
        """
        sudo_command = ['sudo', '-S']

        if preserve_env:
            sudo_command.insert(1, '-E')

        sudo_command.extend(command)

        # Check if sudo requires a password
        if not self.can_sudo_without_password() and self.password is None:
            self.password = getpass(f"[sudo] password for {self.username}: ")

        process = Popen(sudo_command, stdin=PIPE if self.password else None,
                                   stderr=PIPE, universal_newlines=True)

        if self.password:
            process.stdin.write(self.password + '\n')
            process.stdin.flush()

        _, stderr = process.communicate()  # Ensure process is cleaned up

        if process.returncode != 0:
            raise CalledProcessError(process.returncode, sudo_command, stderr)
