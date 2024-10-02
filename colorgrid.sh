#!/usr/bin/env bash

LC_ALL=C
LANG=C
set -e
set -o nounset
set -o pipefail
set -u

printf "\n" ""

for ITER in {16..51}
do
    NUM=${ITER##0}
    tput setaf ${ITER##0}
    tput setab ${ITER##0}
    printf "%3s" "${ITER}"

    if [ $((NUM % 3)) -eq 0 ]
    then
        tput sgr0
        printf "%3s" ""

        for RUN in {34,70,106,142,178}
        do
            NUM_MOD=$((${NUM} + ${RUN}))
            for ITER_2 in {1..3}
            do
                tput setaf ${NUM_MOD##0}
                tput setab ${NUM_MOD##0}
                printf "%3s" "${NUM_MOD}"
                NUM_MOD=$((${NUM_MOD} + 1))

                if [ ${ITER_2} -eq 3 ]
                then
                    tput sgr0
                    if [ ${RUN} -eq 178 ]
                    then
                        printf "%3s\n" ""
                    else
                        printf "%3s" ""
                    fi
                fi
            done
        done
    fi
done

printf "\n" ""
