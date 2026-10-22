#!/bin/sh
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --output eDP-1-1 --auto --pos 0x0 --primary --output HDMI-0 --auto --below eDP-1-1
