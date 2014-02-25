#!/bin/bash
# Mounts a VirtualBox shared folder
# https://help.ubuntu.com/community/VirtualBox/SharedFolders

echo GID=$GID
echo "sudo -E mount -t vboxsf -o uid=$UID,gid=$(echo $GID) uhome ~/uhome"

