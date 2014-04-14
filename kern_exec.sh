#!/bin/bash

LANG=C
set -e
set -o pipefail
NAME=$(basename $0)
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

# check for sudo / root
R_UID="0"
[ "${UID}" -ne "${R_UID}" ] && { printf "\nNeeds sudo\n" ; exit 1 ; }

function pause()
{
  read -p "$*"
}

kern_select()
{
  typeset -r MAINPROMPT="Select a kernel to use: "
  declare -a ARR=(`for KERN in /boot/vm* ; do echo $KERN | cut -d/ -f3; done`)
  PS3=$MAINPROMPT
  clear
  select KRN in "${ARR[@]}"; do
    case "${KRN}" in
      ${KRN}) kern_menu ;;
    esac
  done
}

kern_menu()
{
  printf "\nyou picked: ${KRN} -- Is this correct ? [YN]: "
  read YN
  case "${YN}" in
    [Yy][Ee][Ss]|[Yy]) kern_kexec ;;
    [Nn][Oo]|[Nn]|*)  KERN="" ; kern_select ;;
  esac
}

kern_kexec()
{
  [ ! -z $(sudo which kexec) ] && KEXEC="/usr/sbin/kexec " ||
    { printf -- "%s\n" "Missing kexec"; exit 1; }
  printf "\n# kexec -l /boot/${KRN} --reuse-cmdline\n"
  printf "# kexec -e\n\n"
  printf "\nARE YOU SURE YOU WANT TO RUN THIS ? [YN]: "
  read YN
  case "${YN}" in
    [Yy][Ee][Ss]|[Yy]) printf "\nRunning Kexec\n"
      pause "Press [ENTER] to continue. . ."
      kexec -l /boot/${KRN} --reuse-cmdline
      pause "Press [ENTER] to load ${KRN}. . ."
      kexec -e
    ;;
    [Nn][Oo]|[Nn]|*) printf "Quitting. . .\n" ; exit 0 ;;
  esac
}

kern_select
