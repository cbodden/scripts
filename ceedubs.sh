#!/bin/bash

declare -A CW_DICT=(
['A']='.-'   ['B']='-...' ['C']='-.-.' ['D']='-..'  ['E']='.'   ['F']='..-.'
['G']='--.'  ['H']='....' ['I']='..'   ['J']='.---' ['K']='-.-' ['L']='.-..'
['M']='--'   ['N']='-.'   ['O']='---'  ['P']='.--.' ['Q']='--.-' ['R']='.-.'
['S']='...'  ['T']='-'    ['U']='..-'  ['V']='...-' ['W']='.--' ['X']='-..-'
['Y']='-.--' ['Z']='--..'
['1']='.----' ['2']='..---' ['3']='...--' ['4']='....-' ['5']='.....'
['6']='-....' ['7']='--...' ['8']='---..' ['9']='----.' ['0']='-----'
)

## Dit: 1 unit
## Dah: 3 units
## Intra-character space (the gap between dits and dahs within a character): 1 unit
## Inter-character space (the gap between the characters of a word): 3 units
## Word space (the gap between two words): 7 units

clear

echo "Enter length of word to practice [1-20]: "
read _LEN

_IN=$( awk -v var1=${_LEN} 'length() == var1' /usr/share/dict/web2 \
    | shuf -n $(shuf -i 1-1 -n 1) \
    | tr '[:lower:]' '[:upper:]' \
)
# _IN=$( echo ${1} | tr '[:lower:]' '[:upper:]')
_WORD="${_IN}"

echo "Practice word is : ${_WORD}"

for (( ITER=0; ITER<${#_WORD}; ITER++ ))
do
    _CHAR="${_WORD:${ITER}:1}"
    _MSG="${CW_DICT[$_CHAR]}"

    echo "Letter is ${_CHAR}"
    echo "Morse char is ${CW_DICT[$_CHAR]}"

    play -q -n synth 1 sin 000

    ITER2=0
    while [[ ITER2 -lt ${#_MSG} ]]
    do
        _CW="${_MSG:${ITER2}:1}"
        if [[ "${_CW}" == "-" ]]
        then
            play -q -n synth 0.3 sin 700
            play -q -n synth 0.1 sin 000
        elif [[ "${_CW}" == "." ]]
        then
            play -q -n synth 0.1 sin 700
            play -q -n synth 0.1 sin 000
        fi
        ITER2=$((ITER2+1))
    done
done

# need to add :
## multiwords
## no output option till end (testing mode)
## choice between input or dict file
## number practice (mix letters and numbers also)
## variable speed (1-3)
## more to add.....
