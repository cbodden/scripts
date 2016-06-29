#!/usr/bin/env bash

readonly BC=$(which bc)

function main()
{
    if [ -z ${BC} ]; then
        printf "%s\n" "bc not found."
        exit 1
    fi
}

function precheck()
{
    FM_PRE=$(echo $(\
        awk '/MemFree/ {print $2}' /proc/meminfo ) /1024.0 \
            | ${BC} )
    local CM_PRE=$(echo $(\
        awk '/^Cached/ {print $2}' /proc/meminfo ) /1024.0 \
            | ${BC} )
    local M_TOT=$(echo $(\
        awk '/MemTotal/ {print $2}' /proc/meminfo ) /1024.0 \
            | ${BC} )
    printf "%s\n" "" "This script clears cached mem and free's up ram." \
        "cached memory : ${CM_PRE}mb" \
        "free memory   : ${FM_PRE}mb" \
        "total memory  : ${M_TOT}mb" ""
}

function check()
{
    # clear pagecache, dentries and inodes
    sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
    local FM_POST=$(echo $(\
        awk '/MemFree/ {print $2}' /proc/meminfo ) /1024.0 \
            | ${BC} )
    printf "%s\n" "memory freed  : $(\
        echo "${FM_POST} - ${FM_PRE}" \
            | ${BC} )mb" \
        "total free    : ${FM_POST}mb" ""
}

main
precheck
check
