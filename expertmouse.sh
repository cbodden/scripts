#!/usr/bin/env bash

# set udev rules with :
## sudo udevadm control --reload

# test : 
## sudo systemd-hwdb update \
## ; sudo udevadm trigger \
## ; sudo udevadm info /dev/input/eventX

##set -x
DISPLAY=":0"
HOME=/home/cbodden
XAUTHORITY=${HOME}/.Xauthority
export DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY HOME=$HOME

## test if expert mouse is enabled in
MOUSE=$(\
    xinput list \
    | awk -F'=' '/ExpertBT5.0 Mouse/ {print substr($2,1,2)}')

if [ ! -z ${MOUSE} ]
then
    ## disable internal trackpad if expert mouse enabled
    PROP="0"

    ## change accel profile
    ## xinput set-prop ${MOUSE} 279 -1
    xinput set-prop ${MOUSE} "Device Accel Profile" -1

    ## enable .3 deceleration
    ## xinput set-prop ${MOUSE} 280 0.300000
    xinput set-prop ${MOUSE} "Device Accel Constant Deceleration" 0.300000
else
    ## enable internal trackpad if expert mouse disabled
    PROP="1"
fi

## disable trackpad
xinput set-prop $(\
    xinput list \
    | awk -F'=' '/[Tt]ouch[Pp]ad/ {print substr($2,1,2)}') \
    "Device Enabled" ${PROP}
