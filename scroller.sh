#!/bin/bash
# vim:set ts=2 sw=4 noexpandtab:
# <cesar@pissedoffadmins.com> 2013

SLEEP="0.05" # speed of scroller
NAME=$(basename $0)

function reverse()
{
  STRING=$1
  LEN=${#STRING}
  while test $LEN -gt 0; do
    REV=$REV$(echo $STRING | cut -c $LEN)
    LEN=$((LEN - 1))
  done
  printf $REV
}

function usage()
{
    cat << EOF

Usage: ${NAME} <1|2|3>

    ${NAME} 1 = /-\|

    ${NAME} 2 = ,.oO@Oo.,

    ${NAME} 3 = ░▒▓█▒░

EOF
}

[[ $# -eq 0 ]] && { usage; exit 1; }
case "$1" in
    "1"|"-1") ANIM="/-\|";      ANIM_L="$(reverse $ANIM)"; ANIM_LN=${#ANIM} ;;
    "2"|"-2") ANIM=",.oO@Oo.,"; ANIM_L="$(reverse $ANIM)"; ANIM_LN=${#ANIM} ;;
    "3"|"-3") ANIM="░▒▓█▒░";    ANIM_L="$(reverse $ANIM)"; ANIM_LN=${#ANIM} ;;
    *) usage ; exit 1 ;;
esac

PAD_SIZE=$(($(tput cols)/2))
PSN=`printf "%${PAD_SIZE}s\n" " "`
PSN_LN=${#PSN}

FCNT=0      # forward count
RBIT=0      # reverse bit
l=0         # $ANIM  position count
PR_CNT=0    # $ANIM reverse position count "$p"

while :; do
  [[ $RBIT -eq 1 ]] && { L=$ANIM_L; PR_CNT=$(($PSN_LN - $FCNT)); } ||
    { L=$ANIM; PR_CNT=$FCNT; }
  printf "${PSN:0:$PR_CNT} ${L:$l:1} ${PSN:$PR_CNT:$PSN_LN}\r"
  [[ $FCNT -eq $PSN_LN ]] && { FCNT=0; [[ $RBIT -eq 1 ]] && RBIT=0 || RBIT=1; }
  FCNT=$((FCNT + 1)); l=$((l + 1))
  [[ $l -eq $ANIM_LN ]] && l=0
  sleep $SLEEP
done
