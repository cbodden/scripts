#!/usr/bin/env bash
#===============================================================================
#          FILE: wifi_bar_info.sh
#         USAGE: ./wifi_bar_info.sh
#   DESCRIPTION: gives your essid and quality for use in tmux or xmobar
#       OPTIONS: none
#  REQUIREMENTS: wireless-tools, awk
#          BUGS: probably a bunch
#        AUTHOR: Cesar Bodden (), cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 03/19/2019 06:14:26 PM EDT
#      REVISION: .1
#===============================================================================

case "$(echo $SHELL 2>/dev/null)" in
    '/bin/bash')
        set -o nounset
        set -o pipefail
        ;;
esac

DEPS="iwconfig"
for _DEPS in ${DEPS}
do
    if [ -z "$(which ${_DEPS} 2>/dev/null)" ]
    then
        printf "%s\n" \
            "${_DEPS} not found"
        exit 1
    fi
done

_IFACE=$(\
    iwconfig 2>&1 \
    | awk '/IEEE/ {print $1}')

_ESSID=$(\
    iwconfig ${_IFACE} 2>&1 \
    | awk -F '"' '/ESSID/ {print $2}')

if [[ -z ${_ESSID} ]]
then
    printf "%s\n" "No wifi detected"
    exit 0
fi

_STR=$(\
    iwconfig ${_IFACE} 2>&1 \
    | awk -F '[ |=]' '/Quality/ {print $13}')

_BAR=$(\
    expr ${_STR%%/*} / 10)

_TIC=$(eval \
    printf "X%.0s" {1..${_BAR}})

_MRK=$(eval \
    printf "%s%-$((${_STR##*/}/10))s%s" "[" "${_TIC}" "]" \
    | tr ' ~' '- ')

echo ${_ESSID} ${_MRK}
