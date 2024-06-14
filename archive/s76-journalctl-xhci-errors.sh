#!/bin/bash

gnome-terminal --geometry=921x547+-26+459 --name=s76-journalctl-xhci-errors --title=System76-journalctl-xhci-errors -- bash -c "sudo journalctl -f | grep xhci_hcd"