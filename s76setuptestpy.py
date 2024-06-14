#!/usr/bin/python3
""" Check for modules needed by test.py
"""

def main():
    """ try import except exit 42
    """
    try:
        # pylint: disable=import-outside-toplevel
        # pylint: disable=unused-import
        import psutil
        import cpuinfo
        import pySMART
        import pyamdgpuinfo
        import pynvml
        # pylint: enable=unused-import
        # pylint: enable=import-outside-toplevel
    except ModuleNotFoundError:
        exit(42)

if __name__ == "__main__":
    main()
