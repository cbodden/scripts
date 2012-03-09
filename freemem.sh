#!/bin/bash

BC=`which bc`

if [ -z $BC ]; then
    printf "\nbc not found.\n"
    exit 1
fi

fm_pre=`echo \`cat /proc/meminfo | grep MemFree | tr -s ' ' | cut -d ' ' -f2\`/1024.0 | $BC`
cm_pre=`echo \`cat /proc/meminfo | grep "^Cached" | tr -s ' ' | cut -d ' ' -f2\`/1024.0 | $BC`
m_tot=`echo \`cat /proc/meminfo | grep MemTotal | tr -s ' ' | cut -d ' ' -f2\`/1024.0 | $BC`

printf "This script clears cached mem and free's up some ram.\n"
printf "cached memory : ${cm_pre}mb\n"
printf "free memory   : ${fm_pre}mb\n"
printf "total memory  : ${m_tot}mb\n"

sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

fm_post=`echo \`cat /proc/meminfo | grep MemFree | tr -s ' ' | cut -d ' ' -f2\`/1024.0 | $BC`

printf "\nmemory freed  : `echo "${fm_post} - ${fm_pre}" | $BC`mb\n"
printf "total free    : ${fm_post}mb\n"
