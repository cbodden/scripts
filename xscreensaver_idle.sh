#!/usr/bin/env bash
#===============================================================================
#
#          FILE: xscreensaver_idle.sh
#         USAGE: ./xscreensaver_idle.sh
#
#   DESCRIPTION: deactivates xscreensaver if pacmd has audio
#       OPTIONS: none
#  REQUIREMENTS: pacmd wmctrl xscreensaver
#          BUGS: none so far
#         NOTES: use wisely
#        AUTHOR: Cesar Bodden (), cesar@poa.nyc
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 20-JUL-24
#      REVISION: 2
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
    local _DEPS="pacmd wmctrl xscreensaver"
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
    readonly SLEEP="1m"
}

function _Toggle()
{
    while true
    do
        ${WMCTRL} -m &> /dev/null || exit 1
        local _STATE=$(${PACMD} list-sinks \
            | awk '/*/{c=5}c&&c--' \
            | awk '/state:/ {print $2}')
        if [ ${_STATE} == SUSPENDED ] || [ ${_STATE} == IDLE ]
        then
            sleep ${SLEEP}
        else
            xscreensaver-command -deactivate > /dev/null
            sleep ${SLEEP}
        fi
    done
}

main
_Toggle
