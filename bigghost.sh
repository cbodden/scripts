#!/usr/bin/env bash
#
# this script generates names according to the names from :
# http://www.bigghostlimited.com/?b2w=http://bigghostnahmean.blogspot.com/

[ -z $(which tput 2>/dev/null) ] && { printf "%s\n" "tput not found"; exit 1; }

GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); CLR=$(tput sgr0)

PRE=("" "Muthafuckin wise n powerful"
  "That muthafucka wit two iron midgets for hands" "The almighty"
  "The grand emperor" "The grand royal" "The high and exalted" 
  "The illustrious" "The imperial" "The magnificent" "The majestic"
  "The super supreme" "The unfuckwittable" "The world famous"
  "Ya boy the immortal illustrious" "Ya boy")
PRE_INDEX=$(( $RANDOM % ${#PRE[*]} ))
PRE_W_CNT=$(( ${#PRE[$PRE_INDEX]} ))
PRE_OUT=${GRN}${PRE[$PRE_INDEX]}

MID1=("Acrobatic" "Bandana" "Broccoli" "Caviar" "Cocaine" "Diamond" "Divine"
  "Galaxy" "Hands_of_Zeus" "Lamborghini" "Meteor" "Phantom" "Shampoo"
  "Spartacus" "Swole_Ya_Eye" "Thor" "Volcano" "Watch_Ya_Mouf")
MID1_INDEX=$(( $RANDOM % ${#MID1[*]} ))
MID1_W_CNT=$(( ${#MID1[$MID1_INDEX]} ))
if [ `echo ${MID1[$MID1_INDEX]} | cut -d_ -f1 -s | wc -l` -lt 1 ]; then
  MID2=("Biceps" "Bracelets" "Bundles" "Chromosomes" "Deluxe" "Guitars" "Hammer"
    "Hands" "Knuckles" "Ligaments" "Molecules" "Raviolis" "Saxophones"
    "Snowcones" "Tusks")
  MID2_INDEX=$(( $RANDOM % ${#MID2[*]} ))
  MID_W_CNT=$(( ${#MID1[$MID1_INDEX]} + ${#MID2[$MID2_INDEX]} ))
  MID_OUT="${RED}${MID1[$MID1_INDEX]} ${MID2[$MID2_INDEX]}"
else
  MID_W_CNT=$(( ${#MID1[$MID1_INDEX]} ))
  MID_OUT="${RED}`echo ${MID1[$MID1_INDEX]}|tr "_" " "`"
fi

POST=("" "hisself once again live in the flesh n all that" "in the flesh"
  "n all that good shit" "n all that" "namsayin" "so on n so forth nahmean"
  "the Stapleton gladiator namsayin" "the great" "the magnificent"
  "the panty melter" "the wallabee champ" "via amazin wizardry n shit")
POST_INDEX=$(( $RANDOM % ${#POST[*]} ))
POST_W_CNT=$(( ${#POST[$POST_INDEX]} ))
POST_OUT=${YLW}${POST[$POST_INDEX]}${CLR}

printf $(tput clear)
CNT=$(( ${PRE_W_CNT} + ${MID_W_CNT} + ${POST_W_CNT} ))
tput cup $(( $(tput lines) / 2 )) $((( $(tput cols) / 2 ) - ( $CNT / 2 ) ))
printf "${PRE_OUT} ${MID_OUT} ${POST_OUT}"
tput cup $(tput lines) 0
