#!/usr/bin/env bash
#===============================================================================
#
#          FILE: touchpad.sh
#         USAGE: ./touchpad.sh
#
#   DESCRIPTION: toggles trackpad on / off
#       OPTIONS: none
#  REQUIREMENTS: xinput
#          BUGS: none so far
#         NOTES: use wisely
#        AUTHOR: Cesar Bodden (), cesar@poa.nyc
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 01-JUL-24
#      REVISION: 1
#===============================================================================

LC_ALL=C
LANG=C
set -e
set -o nounset
set -o pipefail
set -u
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

function main()
{
    local _DEPS="xinput"
    for ITER in ${_DEPS}
    do
        if [ -z "$(which ${ITER} 2>/dev/null)" ]
        then
            printf "%s\n" \
                ". . .${ITER} not found. . ."
            exit 1
        else
            readonly ${ITER^^}="$(which ${ITER})"
        fi
    done

    readonly NAME=$(basename $0)
    readonly TP_ID=$(${XINPUT} list \
                 | awk -F'=' '/[Tt]ouch[Pp]ad/ {print substr($2,1,2)}')
    readonly TP_LINE=$(${XINPUT} list \
                 | awk -F'=' '/[Tt]ouch[Pp]ad/ {print $0}')
}

function _Toggle()
{
    if [ "$(echo ${TP_LINE} | grep -c "floating")" == "1" ];
    then
        local _DE=1
    else
        local _DE=0
    fi

    ${XINPUT} set-prop ${TP_ID} "Device Enabled" ${_DE}
}

main
_Toggle
