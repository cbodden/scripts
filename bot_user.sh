#!/usr/bin/env bash

NAME=$(basename $0)
clear

if [[ -z $1 || -z $2 ]]
then
    printf "%s\n" \
        "" "Command needs to be run with channel (without #) and nick :" \
        "" "${NAME} CHANNEL NICK" ""
    exit
fi

CHAN="$1"
USER="$2"
PW="$(\
    tr -dc A-Za-z0-9 </dev/urandom \
    | head -c 13 ; echo '' \
    )"

# adding a user to admin and to channel
printf "%s\n" \
    "" "user register ${USER} ${PW}" "" \
    "# admin capabilities"
for ITER in admin ban invite kick op topic voice
do
    echo "admin capability add ${USER} ${ITER}"
done

printf "%s\n" \
    "" "# channel capabilities"
for ITER in admin ban invite kick op topic voice
do
    echo "channel capability add #${CHAN} ${USER} ${ITER}"
done

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
