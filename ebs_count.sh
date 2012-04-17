#!/bin/bash

ec2-describe-instances | grep -A 7 pmg-ebs1 | awk 'NR > 4' | awk '{print $3}' | while read LINE
    do 
        let count++
        #set EBS${count}="$LINE"
        eval EBS${count}="$LINE"
        #echo $(${EBS}${count})

    done
echo "ebs1 == $EBS1"
