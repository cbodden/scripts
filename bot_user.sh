#!/usr/bin/env bash

NAME=$(basename $0)
clear

if [[ -z $1 || -z $2 ]]
then
    printf "%s\n" \
        "" "Command needs to be run with nick and channel (without #):" \
        "" "${NAME} CHANNEL NICK" ""
    exit
fi

CHAN="$1"
USER="$2"
PW="$(\
    tr -dc A-Za-z0-9 </dev/urandom \
    | head -c 13 ; echo '' \
    )"

# adding a user to hkc
printf "%s\n" \
    "user register ${USER} ${PW}" "" \
    "# admin capabilities" \
    "admin capability add ${USER} admin" \
    "admin capability add ${USER} ban" \
    "admin capability add ${USER} invite" \
    "admin capability add ${USER} kick" \
    "admin capability add ${USER} op" \
    "admin capability add ${USER} topic" \
    "admin capability add ${USER} voice" "" \
    "# channel capabilities" \
    "channel capability add #${CHAN} ${USER} admin" \
    "channel capability add #${CHAN} ${USER} ban" \
    "channel capability add #${CHAN} ${USER} invite" \
    "channel capability add #${CHAN} ${USER} kick" \
    "channel capability add #${CHAN} ${USER} op" \
    "channel capability add #${CHAN} ${USER} topic" \
    "channel capability add #${CHAN} ${USER} voice"

# send to user
printf "%s\n" \
    "" "" "PM below to the user" "" "" \
    "# user actions (PM the bot these)" \
    "## change password which is : ${PW}" \
    "user set password ${USER} ${PW} <NEW PASSWORD>" "" \
    "## identify to the bot (login)" \
    "user identify ${USER} <NEW PASSWORD>" "" \
    "## if you want to identify by hostmask and not password" \
    "## run the following :" \
    "user register ${USER} !" \
    "user hostmask remove" \
    "user hostmask" \
    "user hostmask add" "" \
    "## show bot commands" \
    "help" ""
