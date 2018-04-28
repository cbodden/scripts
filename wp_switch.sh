#!/usr/bin/env bash

_REZ=$(awk '/*+/ {print $1}' <(xrandr))
_PATH=~/wallpapers/
_F=$(ls ${_PATH} | shuf -n 1)
_FILE=${_PATH}$(echo ${_F})
_IMG_ID=$(identify ${_FILE})
_IMG_SIZE=$(awk '{print $3}' <(echo ${_IMG_ID}))

if [[ ${_IMG_SIZE%x*} -gt ${_REZ%x*} ]] || [[ ${_IMG_SIZE#*x} -gt ${_REZ#*x} ]]
then
    _MAX=--bg-max
else
    _MAX=""
fi

$(which feh) \
    --no-fehbg \
    --bg-center \
    --image-bg black \
    ${_MAX} \
    --quiet \
    ${_FILE} 2>&1
