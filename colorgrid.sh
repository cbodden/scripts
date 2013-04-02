#!/bin/bash

function cgrid() {
    for x in $(seq -w 029 047); do
        echo -n ${x}\;X "| "
        for y in $(seq -w 029 047); do
            if [ "$x" == "029" ]; then
                echo -en "\033[4m" ${x}\;${y} "\033[0m"
            else
                echo -en "\033[${x};${y}m" ${x}\;${y} "\033[0m"
            fi
        done
        printf "\n"
    done
}

function pgrid() {
    for x in $(seq -w 089 107); do
        echo -n ${x}\;X "| "
        for y in $(seq -w 089 107); do
            if [ "$x" == "089" ]; then
                echo -en "\033[4m" ${x}\;${y} "\033[0m"
            else
                echo -en "\033[${x};${y}m" ${x}\;${y} "\033[0m"
            fi
        done
        printf "\n"
    done
}

case $1 in
    'normal'|'regular'|'standard')
        cgrid
    ;;

    'pastel'|'pastels')
        pgrid
    ;;

    'all')
        cgrid
        printf "\n"
        pgrid
    ;;

esac
