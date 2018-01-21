#!/usr/bin/env bash

_FNAME=""
_OPTIN="-a -t"

if [ ! -x "$(command -v sxiv)" ]
then
    printf "\n%s\n\n" \
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
shift $((OPTIND-1))

declare -a _FILES=($(\
    find . -maxdepth 1 -name '*' -exec file {} \; \
    | grep -o -P '^.+: \w+ image' \
    | cut -d: -f1 \
    | sed -e 's/.\///'))

if [[ "${#_FILES[@]}" -eq "0" ]]
then
    printf "\n%s\n\n" \
        "no image files in this directory"
    exit 1
fi

for ITER in ${_FILES[@]}
do
    _FNAME="${ITER},${_FNAME}"
done

_FOUT=$(echo ${_FNAME} \
    | sed -e 's/[^,]//g' \
    | wc -c)

if [ "${_FOUT}" -le "1" ]
then
    eval sxiv ${_OPTIN} ${_FNAME}
else
    eval sxiv ${_OPTIN} \{${_FNAME}\}
fi
