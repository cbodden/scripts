#!/bin/bash

## test for sysctl
if [ -z "$(which sysctl)" ]; then
  printf "\nsysctl missing.\n"
  exit 1
fi

## test for getconf
if [ -z "$(which getconf)" ]; then
  printf "\ngetconf missing.\n"
  exit 2
fi

MEMTOTAL=`cat /proc/meminfo | awk '/MemTotal/ {print $2}'`
EXIST_SHMMAX=`$(which sysctl) -n kernel.shmmax`
EXIST_SHMALL=`$(which sysctl) -n kernel.shmall`
EXIST_SHMMNI=`$(which sysctl) -n kernel.shmmni`
EXIST_PAGESIZE=`$(which getconf) PAGE_SIZE`
EXIST_PHYSPAGES=`$(which getconf) _PHYS_PAGES`
NEW_SHMMALL=`expr ${EXIST_PHYSPAGES} / 2`
NEW_SHMMAX=`expr ${NEW_SHMMALL} \* ${EXIST_PAGESIZE}`

## if zero output for either pagesize or physpages then exit
if [ -z "$EXIST_PAGESIZE" ] || [ -z "$EXIST_PHYSPAGES" ]; then
  printf "\nError: Check $(which getconf) output\n"
  exit 3
fi

## if zero output for either shmmax, shmall, or shmmni then exit
if [ -z "$EXIST_SHMMAX" ] || [ -z "$EXIST_SHMALL" ] || [ -z "$EXIST_SHMMNI" ]; then
  printf "\nError: Check $(which sysctl) output\n"
  exit 4
fi

## printing out all information to make life easier
printf "\nmemtotal = %d mb" ${MEMTOTAL}
printf "\nkernel.shmmax = %d" ${EXIST_SHMMAX}
printf "\nkernel.shmall = %d" ${EXIST_SHMALL}
printf "\nkernel.shmmni = %d" ${EXIST_SHMMNI}
printf "\npage_size = %d" ${EXIST_PAGESIZE}
printf "\nphys_pages = %d" ${EXIST_PHYSPAGES}
printf "\n\nnew shmmall = `expr ${EXIST_PHYSPAGES} / 2`"
printf "\nnew shmmax = `expr ${NEW_SHMMALL} \* ${EXIST_PAGESIZE}`\n\n"
printf "\nsetting shmmax & shmmall now.\n\n"

## running sysctl to change settings. not sticky during a reboot
$(which sysctl) -w kernel.shmall=${NEW_SHMMALL}
$(which sysctl) -w kernel.shmmax=${NEW_SHMMAX}

## edding to /etc/sysctl.conf to make sticky accross reboots
echo "kernel.shmall=${NEW_SHMMALL}" >> /etc/sysctl.conf
echo "kernel.shmmax=${NEW_SHMMAX}" >> /etc/sysctl.conf

# vim:set ts=4 sw=4 noexpandtab:
