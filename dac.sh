#!/usr/bin/env bash
#===============================================================================
#
#          FILE: dac.sh
#
#         USAGE: ./dac.sh
#
#   DESCRIPTION: this script sets your asoundrc for a usb dac
#  REQUIREMENTS: alsa and aplay
#          BUGS: probably
#         NOTES: tested with onboard intel hd audio and a usb Fiio Q1
#        AUTHOR: Cesar (), cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 12/11/2019
#===============================================================================

clear

declare -a _CARDS=($(aplay -l \
    | awk '/^card/ {print $1,$2,$3}' \
    | tr " " "_" \
    | sort -u))


if [[ ${#_CARDS[*]} -gt 1 ]]
then
    _CNT=0
    for ITER in "${_CARDS[@]}"
    do
        echo [${_CNT}] ${ITER}
        let _CNT++
    done

    printf "%s\n" "" \
        "Choose the sound card (by number) : "

    read -a _CARD_READ

    _CARD_OUT=$( echo ${_CARDS[${_CARD_READ}]} \
        | tr "_" " " )

    _CARD_NUM=$( echo ${_CARD_OUT} \
        | awk '{print $2}' \
        | tr -d ':' )

else
    printf "%s\n" "" \
        "There is only one card so using the default"

    _CARD_OUT=$( echo ${_CARDS[0]} \
        | tr "_" " " )

    _CARD_NUM=$( echo ${_CARD_OUT} \
        | awk '{print $2}' \
        | tr -d ':' )
fi

printf "%s\n" "" \
    "You selected : ${_CARD_OUT}" "" \
    "If this is correct press enter to continue"

read -p "$*"

cat >~/.asoundrc <<EOF
pcm.!default {
    type hw
    card ${_CARD_NUM}
}

ctl.!default {
    type hw
    card ${_CARD_NUM}
}
EOF

printf "%s\n" "" \
    "Restarting alsa now"

sudo /etc/init.d/alsasound restart

printf "%s\n" "" \
    "You should restart whatever application needed sound."
