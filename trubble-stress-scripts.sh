#!/usr/bin/env bash

rsync -avz --delete --filter='merge rsync-filter.txt' -e ssh ./ system76@10.17.89.69:./user/Documents/stress-scripts/
ssh system76@10.17.89.69 "cd user; tar -c -I 'xz -9 -T8' -f stress-scripts.tar.xz Documents .local .ssh"
ssh -t system76@10.17.89.69 "sudo rm -rvf /opt/fileserv/files/stress-scripts.tar.xz.old; sudo mv /opt/fileserv/files/stress-scripts.tar.xz /opt/fileserv/files/stress-scripts.tar.xz.old; sudo mv user/stress-scripts.tar.xz /opt/fileserv/files"