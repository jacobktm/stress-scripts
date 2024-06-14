#!/bin/bash

gnome-terminal --name=s76-cpu-mhz --title=System76-cpu-mhz --geometry=868x25+-26+9 -- bash -c "watch -n .1 'cat /proc/cpuinfo | grep MHz'"
