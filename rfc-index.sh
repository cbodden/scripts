#!/bin/bash

# vim:set ts=2 sw=4 noexpandtab:
# <cesar@pissedoffadmins.com> 2013

# todo :
# add history with rfc number read - time stamped (function)

set -e
set -o pipefail

NAME=$(basename $0)

version()
{
  local VER="0.18"
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

# temp file and trap statement - trap for clean end
case "$(uname 2>/dev/null)" in
  'Linux') TMP_FILE=$(mktemp --tmpdir rfc.$$.XXXXXXXXXX);;
  'Darwin') TMP_FILE=$(mktemp rfc.$$.XXXXXXXXXX);;
esac
trap "rm -rf ${TMP_FILE}" 0 1 2 3 15

# check if $1 != "search"
if [ $1 != "search" ]; then
  # check if $# -eq 2 && $2 is an integer
  [ $# -eq 2 ] || { version; descrip; usage; exit 1; }
  [ ${2} -ne 0 -o ${2} -eq 0 2>/dev/null ] || { version; descrip; usage; exit 1; }
  # prepend zeros to make id number <####>
  FN=`printf "%04d" ${2} | xargs`
fi

# emulator / viewer settings
[[ -n $(command -v xterm) ]] && EM="xterm" || EM="urxvt"
case "${EM}" in
  'xterm') EM=$(which xterm 2>/dev/null);;
  'mrxvt') EM=$(which mrxvt 2>/dev/null);;
  'urxvt') EM=$(which urxvt 2>/dev/null);;
esac

EM_SETTINGS="-fg green -bg black -bd green -g 72x59 -T"
EM_TITLE="${NAME} - rfc${FN}.txt"
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
    if [ -z $(wget -q --spider http://www.rfc-editor.org/rfc/rfc${2}.txt || echo $?) ]; then
      printf -- "%s\n" "Downloading ${FN}"
      curl -f -s http://www.rfc-editor.org/rfc/rfc${2}.txt | \
        awk '{line++; print}; /\f/ {for (i=line; i<=58; i++) print ""; line=0}' | \
        sed '/\f/d' > "${TMP_FILE}"
      printf -- "%s\n" "Showing ${FN}"
      ${EM} ${EM_SETTINGS} "${EM_TITLE}" -e ${PAGER} "${TMP_FILE}"
    else
      printf -- "%s\n" "File does not exist. Check RFC number : ${FN}"
      usage
    fi
  ;;

  'search')
    F=`echo ${2} | head -c 1`
      FU=`echo ${F} | tr -s '[:lower:]' '[:upper:]'`
      FL=`echo ${F} | tr -s '[:upper:]' '[:lower:]'`
    CW=`echo ${2} | cut -c2-`
    curl -s http://www.rfc-editor.org/rfc/rfc-index.txt | \
      awk 'BEGIN{FS="\n";RS="";ORS="\n\n"}/'[${FU}${FL}]${CW}'/' > "${TMP_FILE}"
    printf -- "%s\n" "Showing serach for '${FL}${CW}'"
    ${EM} ${EM_SETTINGS} "${EM_TITLE}" -e ${PAGER} "${TMP_FILE}"
  ;;

  *) printf -- "\n"; usage; exit 1;;
esac
