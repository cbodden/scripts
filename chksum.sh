#!/usr/bin/env bash
set -e
set -o pipefail
clear
NAME=$(basename $0)

usage()
{
  cat <<EOL
  ${NAME} <file>

EOL
}

[ $# -lt 1 ] && { usage; exit 1; }
[ -e ${1} ] || { usage; exit 1; }

declare -a _SUMS=(md5sum shasum sha1sum sha224sum sha256sum sha384sum sha512sum)
printf "%12s%0s\n" "FILE: " "$(echo ${1})"
printf "%12s%0s\n" "SIZE: " "$(ls -alh ${1} | awk '{ print $5 }')"
for _LIST in "${_SUMS[@]}"; do
  printf "%12s"  "$(echo ${_LIST} | tr '[:lower:]' '[:upper:]'): "
  printf "$(/usr/bin/${_LIST} ${1} | awk '{ print $1 }')\n"
done
printf "\n"
