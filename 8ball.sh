#!/bin/bash

GRN=$(tput setaf 2)
YLW=$(tput setaf 3)
RED=$(tput setaf 1)
CLR=$(tput sgr0)

ANSWERS=(
"`echo -n "${GRN}●${CLR} It is certain"`"
"`echo -n "${GRN}●${CLR} It is decidedly so"`"
"`echo -n "${GRN}●${CLR} Without a doubt"`"
"`echo -n "${GRN}●${CLR} Yes definitely"`"
"`echo -n "${GRN}●${CLR} You may rely on it"`"
"`echo -n "${GRN}●${CLR} As I see it yes"`"
"`echo -n "${GRN}●${CLR} Most likely"`"
"`echo -n "${GRN}●${CLR} Outlook good"`"
"`echo -n "${GRN}●${CLR} Yes"`"
"`echo -n "${GRN}●${CLR} Signs point to yes"`"
"`echo -n "${YLW}●${CLR} Reply hazy try again"`"
"`echo -n "${YLW}●${CLR} Ask again later"`"
"`echo -n "${YLW}●${CLR} Better not tell you now"`"
"`echo -n "${YLW}●${CLR} Cannot predict now"`"
"`echo -n "${YLW}●${CLR} Concentrate and ask again"`"
"`echo -n "${RED}●${CLR} Dont count on it"`"
"`echo -n "${RED}●${CLR} My reply is no"`"
"`echo -n "${RED}●${CLR} My sources say no"`"
"`echo -n "${RED}●${CLR} Outlook not so good"`"
"`echo -n "${RED}●${CLR} Very doubtful"`"
)

MOD=${#ANSWERS[*]}
INDEX=$(($RANDOM%$MOD))
WORD=${#ANSWERS[$INDEX]}

echo $(tput clear)
tput cup $(($(tput lines)/2)) $((($(tput cols)/2)-($WORD/2)+4))
echo -n "${ANSWERS[$INDEX]}"
tput cup $(tput lines) 0
