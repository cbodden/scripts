#!/usr/bin/env bash

_FTYPE="bmp
gif
jpg
png"

_FNAME=""
_OPTIN="-a -t"

if [ ! -x "$(command -v sxiv)" ]
then
    printf "\n%s\n" \
        "-=-=-=-= sxiv not installed =-=-=-=-"
    exit 1
fi

while getopts "f" OPT
do
    case "${OPT}" in
        'f') _OPTIN="-f ${_OPTIN}"
            ;;
    esac
done
## [ ${OPTIND} -eq 1 ] && { usage ; }
shift $((OPTIND-1))

for ITER in ${_FTYPE}
do
    _FCNT=$(ls *.${ITER} 2> /dev/null \
        | wc -l)
    if [ "${_FCNT}" != "0" ]
    then
        _FNAME="${ITER},${_FNAME}"
    fi
    _FEDIT=${_FNAME/%,/}
done

_FOUT=$(echo ${_FEDIT} \
    | sed -e 's/[^,]//g' \
    | wc -c)

if [ "${_FOUT}" -le "1" ]
then
    eval sxiv ${_OPTIN} *.${_FEDIT}
else
    eval sxiv ${_OPTIN} *.\{${_FEDIT}\}
fi
