#!/usr/bin/env bash

##set -x
DISPLAY=":0.0"
HOME=/home/cbodden/
XAUTHORITY=$HOME/.Xauthority
export DISPLAY XAUTHORITY HOME

## test if hhkb is plugged in
KEEB=$(\
    xinput list \
    | awk -F'=' '/HHKB-Hybrid_1 Keyboard/  {print substr($2,1,2)}')

if [ ! -z ${KEEB} ]
then
    ## disable internal keyboard if HHKB plugged in
    PROP="0"
else
    ## enable internal keyboard if HHKB plugged in
    PROP="1"
fi

## disable
xinput set-prop $(\
    xinput list \
    | awk -F'=' '/Set 2 keyboard/ {print substr($2,1,2)}') \
    "Device Enabled" ${PROP}
