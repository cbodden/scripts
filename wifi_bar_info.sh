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
#      REVISION: .2
#===============================================================================

case "$(echo $SHELL 2>/dev/null)" in
    '/bin/bash')
        set -o nounset
        set -o pipefail
        ;;
esac

if [[ -z "$(which iw 2>/dev/null)" && -z "$(which iwconfig 2>/dev/null)" ]]
then
    echo "WIFI tools not found"
    exit 1
fi

if [ -n "$(which iw 2>/dev/null)" ]
then

    _IFACE=$(\
        iw dev 2>&1 \
        | awk '/Interface/ {print $2}')

    _ESSID=$(\
        iw dev ${_IFACE} link 2>&1 \
        | awk '/SSID:/ {print $2}')

    if [[ -z ${_ESSID} ]]
    then
        printf "%s\n" "No wifi detected"
        exit 1
    fi

    _PCT=$(\
        awk 'NR==3 {printf("%.0f%\n",$3*10/7)}' /proc/net/wireless)

    _TIC=$(eval \
        printf "X%.0s" {1..10})

    _MRK=$(eval \
        printf "%s%-$((${_PCT%%%*}/10))s%s" "[" "${_TIC}" "]" \
        | tr ' ~' '- ')

    echo ${_ESSID} ${_MRK}

else

    _IFACE=$(\
        iwconfig 2>&1 \
        | awk '/IEEE/ {print $1}')

    _ESSID=$(\
        iwconfig ${_IFACE} 2>&1 \
        | awk -F '"' '/ESSID/ {print $2}')

    if [[ -z ${_ESSID} ]]
    then
        printf "%s\n" "No wifi detected"
        exit 1
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

fi
