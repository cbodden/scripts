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

_SUB=$1 ; shift
if [[ ! -d "${_SUB}" ]]
then
    _SUB="."
fi

declare -a _FILES=($(\
    find ${_SUB} -maxdepth 1 -name '*' -exec file {} \; \
    | grep -o -P '^.+: \w+ image' \
    | cut -d: -f1 \
    | sort -g ))
    # | sed -e 's/.\///'))

if [[ "${#_FILES[@]}" -eq "0" ]]
then
    printf "\n%s\n\n" \
        "no image files in this directory"
    exit 1
fi

for ITER in ${_FILES[@]}
do
    _FNAME="${_FNAME},${ITER}"
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
