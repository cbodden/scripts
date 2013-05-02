#!/bin/bash

# <cesar@pissedoffadmins.com> 2013

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# TODO:
#

NAME=$(basename $0)

version()
{
    local VER="0.1"
    printf -- "%s\n" "${NAME} version ${VER}"
    printf -- "%s\n" "<cesar@pissedoffadmins.com> 2013"
    printf -- "%s\n"
}

license()
{
  cat <<EOL
Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty provided the copyright
notice and this notice are preserved.  This file is offered as-is,
without any warranty.
EOL
}

usage()
{
  printf -- "%s\n"
  printf -- "%s\n" "Usage: ${NAME} <####>"
  printf -- "%s\n" "Examples:"
  printf -- "%s\n" "  ${NAME} 1        # displays RFC 0001 index"
}

[ ${1} -ne 0 -o ${1} -eq 0 2>/dev/null ] || { version; license; usage; exit 1; }
FN=`printf "%04d" ${1} | xargs`

case "${FN}" in
  [0-9]|[[0-9][0-9]|[0-9][0-9][0-9]|[0-9][0-9][0-9][0-9])
    curl -s http://www.rfc-editor.org/rfc/rfc-index.txt | \
    awk '/^'${FN}'/ {do_print=1} do_print==1 {print} NF==0 {do_print=0}';;
  *) printf -- "Error: unknown parameter '%s'\n" "$1"; usage; exit 1;;
esac
