#!/bin/bash

# vim:set ts=2 sw=4 noexpandtab:
# <cesar@pissedoffadmins.com> 2013

set -e
NAME=$(basename $0)

version()
{
  local VER="0.2"
  printf -- "%s\n" "${NAME} version ${VER}"
  printf -- "%s\n" "<cesar@pissedoffadmins.com> 2013"
  printf -- "%s\n"
}

descrip()
{
  cat <<EOL
This is a simple script that will show you either the
name / subject of an RFC or let you read an RFC just
by supplying the number.
EOL
}

usage()
{
  printf -- "%s\n"
  printf -- "%s\n" "Usage: ${NAME} <name|read> <####>"
  printf -- "%s\n" "Usage examples:"
  printf -- "%s\n" "  ${NAME} name 3334     # displays RFC 3334 index"
  printf -- "%s\n" "    ex: 3334 Policy-Based Accounting. T. Zseby, S. Zander, C. Carle. October"
  printf -- "%s\n" "             2002. (Format: TXT=103014 bytes) (Status: EXPERIMENTAL)"
  printf -- "%s\n"
  printf -- "%s\n" "  ${NAME} read 1443     # read RFC 1443"
  printf -- "%s\n"
}

## check if $# -eq 2 && $2 is an integer
[ $# -eq 2 ] || { version; descrip; usage; exit 1; }
[ ${2} -ne 0 -o ${2} -eq 0 2>/dev/null ] || { version; descrip; usage; exit 1; }

## prepend zeros to make id number <####>
FN=`printf "%04d" ${2} | xargs`

## temp file and trap statement - trap for clean end
[[ $(uname) == "Linux" ]] && TMP_FILE=$(mktemp --tmpdir rfc.$$.XXXXXXXXXX) \
  || [[ $(uname) == "Darwin" ]] && TMP_FILE=$(mktemp rfc.$$.XXXXXXXXXX)
trap "rm -rf ${TMP_FILE}" 0 1 2 3 15

## editor / viewer settings
[ -x $(which xterm 2>/dev/null) ] && ED="$(which xterm 2>/dev/null)" \
  || [ -x $(which mrxvt 2>/dev/null) ] && ED="$(which mrxvt 2>/dev/null)" \
  || [ -x $(which rxvt 2>/dev/null) ] && ED="$(which urxvt 2>/dev/null)"
ED_SETTINGS="-fg green -bg black -bd green -g 72x59 -T"
ED_TITLE="${NAME} - rfc${FN}.txt"
PAGER=`which less`

case "${1}" in
  'name'|'index')
    case "${FN}" in
      [0-9]|[[0-9][0-9]|[0-9][0-9][0-9]|[0-9][0-9][0-9][0-9])
      curl -s http://www.rfc-editor.org/rfc/rfc-index.txt | \
        awk '/^'${FN}'/ {do_print=1} do_print==1 {print} NF==0 {do_print=0}';;
    *) printf -- "Error: unknown parameter '%s'\n" "$2"; usage; exit 1;;
    esac
  ;;

  'read'|'show')
    printf -- "%s" "Grabbing ${FN}"
    wget -O- -q http://www.rfc-editor.org/rfc/rfc${2}.txt | \
      awk '{line++; print}; /\f/ {for (i=line; i<=58; i++) print ""; line=0}' | \
      sed '/\f/d' > "${TMP_FILE}"
    printf -- "\ndone grabbing\n"
    ${ED} ${ED_SETTINGS} "${ED_TITLE}" -e ${PAGER} "${TMP_FILE}"
  ;;
  *) printf -- "\n"; usage; exit 1;;
esac
