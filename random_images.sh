#!/bin/bash

while :;do
    files=(~/wallpapers/*.jpg ~/wallpapers/*.jpeg ~/wallpapers/*.png ~/wallpapers/*.gif)
    N=${#files[@]}
    ((N=RANDOM%N))
    randomfile=${files[$N]}
    /usr/bin/xv -quit -root -rmode 5 $randomfile
    #/usr/bin/feh --bg-center $randomfile
    #sleep 60
done
