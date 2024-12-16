#!/usr/bin/env bash

## udevadm info -a -n /dev/input/event23
## udevd rule:
# KERNEL=="event*" \
# , SUBSYSTEM=="input" \
# , ATTRS{name}=="HHKB-Hybrid_1 Keyboard" \
# , RUN+="/bin/sh -c '/home/cbodden/git/mine/scripts/keeb.sh'"

## evtest ; cat /sys/class/input/eventXX/device/modalias ; 
## udevadm info -a -n /dev/input/event23
## hwdb rule for key map
## map : https://pkg.go.dev/github.com/holoplot/go-evdev
# evdev:input:b0005v04FEp0021e0001*
#  KEYBOARD_KEY_7008a=key_rightctrl ## Henkan
#  KEYBOARD_KEY_7008b=key_leftmeta  ## Muhenkan


##set -x
DISPLAY=":0"
HOME=/home/cbodden
XAUTHORITY=${HOME}/.Xauthority
export DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY HOME=$HOME

## test if hhkb is plugged in
KEEB=$(\
    xinput list \
    | awk -F'=' '/HHKB-Hybrid_1 Keyboard/  {print substr($2,1,2)}')

if [ -z ${KEEB} ]
then
    ## disable internal keyboard if HHKB plugged in
    sleep 3
    PROP="0"
else
    ## enable internal keyboard if HHKB is unplugged
    PROP="1"
fi

xinput set-prop $(\
    xinput list \
    | awk -F'=' '/Set 2 keyboard/ {print substr($2,1,2)}') \
    "Device Enabled" ${PROP}
