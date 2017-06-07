#!/usr/bin/env bash

LC_ALL=C
LANG=C
NAME=$(basename $0)

PTH="${HOME}/wallpapers/"
CNT=0
RED=$(tput setaf 1)
BLU=$(tput setaf 4)
GRN=$(tput setaf 40)
CLR=$(tput sgr0)

function _RENAME()
{
    _DIR_CNT=$(ls -l ${PTH} \
        | egrep -c '^-')

    if [ "$_DIR_CNT" -lt "1000" ]
    then
        _MASK="%04d"
    else
        _MASK="%05d"
    fi

    for FILE in ${PTH}*
    do
        NUM=$(printf "${_MASK}.${FILE##*.}" "${CNT}")
        _FILE_TST=$(echo ${FILE%%.*} \
            | sed 's/^.*\///')
        if [ "${_FILE_TST}" != "${NUM%%.*}" ]
        then
            printf "%s\n" \
                "Moving ${RED}${FILE}${CLR} to ${BLU}${PTH}${NUM}"
            printf "${CLR}"
            mv -n "${FILE}" "${PTH}${NUM}"
        else
            printf "%s\n" \
                "Not moving ${GRN}${FILE}${CLR}"
            printf "${CLR}"
        fi
        let CNT=$CNT+1
    done
}

_RENAME
