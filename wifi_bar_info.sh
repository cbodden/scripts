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

GRN=$(tput setaf 2)
YLW=$(tput setaf 3)
RED=$(tput setaf 1)
CLR=$(tput sgr0)

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

    _STR=$(\
        iw dev ${_IFACE} link 2>&1 \
        | awk '/signal/ {print $2}')

    if [[ ${_STR} -le -40 && ${_STR} -ge -60 ]]
    then
        ## green
        _COLOR=$(tput setaf 2)
        echo "${_ESSID} [${_COLOR}${_STR}${CLR}/-110]"
    elif [[ ${_STR} -le -61 && ${_STR} -ge -90 ]]
    then
        ## yellow
        _COLOR=$(tput setaf 3)
        echo "${_ESSID} [${_COLOR}${_STR}${CLR}/-110]"
    elif [[ ${_STR} -le -91 && ${_STR} -ge -110 ]]
    then
        ## red
        _COLOR=$(tput setaf 1)
        echo "${_ESSID} [${_COLOR}${_STR}${CLR}/-110]"
    fi

    ## echo "${_ESSID} [${_COLOR}${_STR}${CLR}/-110]"

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
