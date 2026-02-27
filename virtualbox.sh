#!/bin/bash

sudo pacman -Syu virtualbox linux515-virtualbox-host-modules linux518-virtualbox-host-modules virtualbox-guest-utils
yay -S --needed --noconfirm virtualbox-ext-oracle

# If this doesn't work, reboot the system
sudo vboxreload

sudo gpasswd -a $USER vboxusers
