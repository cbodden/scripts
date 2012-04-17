#!/bin/bash

## [ -z $1 ] && { echo "run $0 -help"; exit 1; } || 1="$(echo ${1} | tr 'A-Z' 'a-z')"

case $1 in

'instance'|'volumes')
    TMP_VOL_OUT="$(basename $0).$$.tmp"
    TMP_INST_OUT="$(basename $0).$$.tmp"
    clear
    
    ## input the number of volumes to create 
    echo "How many volumes to create ?:"
    read VOLNUM
    echo "Creating ${VOLNUM} volumes"
    
    ## input size of volume
    echo "What do you want the size of the vols to be (in gb) ?:"
    read VOLSIZE
    echo "Creating ${VOLNUM} ${VOLSIZE}gb volumes"
    
    ## select availability zone
    echo "What zone do you want the volumes to be in :"
    echo "select from list below by inputing zone"
    echo "takes a second to load list - case sensitive"
    ec2-describe-availability-zones | awk '{print $2}'
    read ZONE
    echo "Using ${ZONE} as zone"
    
    ## create the volumes
    x=0
    while [ $x -lt ${VOLNUM} ];
        do
            x=`expr $x + 1`
            ec2-create-volume -s ${VOLSIZE} -z ${ZONE} >> ${TMP_VOL_OUT}
        done
    
    ## create instance
    # first show images / ami's to use as image
    echo "Select default ami to mimic for new instance (just input from column one - case sensitive) :"
    ec2-describe-images | egrep IMAGE | awk '{print $2, $3}'
    read DEF_AMI
    echo "You selected ${DEF_AMI}"
    
    # now select instance type
    echo "Select instance type :"
    echo "m1.small | m1.large | m1.xlarge | c1.medium | c1.xlarge | m2.xlarge | m2.2xlarge | m2.4xlarge | cc1.4xlarge | cg1.4xlarge | t1.micro"
    read INST_TYPE
    echo "You selected ${INST_TYPE}"
    
    # now create the instance
    ec2-run-instances ${DEF_AMI} -k buddymedia --availability-zone ${ZONE} -t ${INST_TYPE} >> ${TMP_INST_OUT}
    
    ## attach the volumes
    x=0
    while [ $x -lt ${VOLNUM} ];
        do
            x=`expr $x + 1`
            VOLNAME=`sed -n `echo $x`p ${TMP_VOL_OUT} | awk '{print $2}'`
            # INSTNAME=`sed -n `echo $x`p ${TMP_INST_OUT} | awk '{print $2}'`
            INSTNAME=`cat ${TMP_INST_OUT} | awk '{print $2}'`
            ec2-attach-volume ${VOLNAME} -i ${INSTNAME} -d /dev/sdh$x
        done
    
    rm -f ${TMP_VOL_OUT}
    rm -f ${TMP_INST_OUT}
;;

'fs_work'|'raid')
    #################
    #### FS work ####
    #################
    
    #######################
    ## from here on down ##
    ## there be dragons  ##
    #######################
    
    ##Zeroes the drives
    dd if=/dev/zero of=/dev/xvdh1
    dd if=/dev/zero of=/dev/xvdh2
    dd if=/dev/zero of=/dev/xvdh3
    dd if=/dev/zero of=/dev/xvdh4
    
    ## create the raid one arrays 
    # did this one real hacky since the need for more that 3 drives per did not exist at time of writing 
    if [ ${VOLNUM} -eq 4 ];
        then
            mdadm --create /dev/md1 --verbose --level=raid1 --raid-devices=2 /dev/xvdh1 /dev/xvdh2
            mdadm --create /dev/md2 --verbose --level=raid1 --raid-devices=2 /dev/xvdh3 /dev/xvdh4
        else
            exit 1
        fi
    
    ##Create a RAID 0 from the RAID 1
    mdadm --create /dev/md3 --verbose --chunk=4 --level=raid0 --raid-devices=2 /dev/md1 /dev/md2
    
    ##LVM Creation
    pvcreate /dev/md3
    vgcreate RAID10 /dev/md3
    lvcreate -n store RAID10
    
    ##Filesystem Creation
    mkfs.ext4 /dev/RAID10/store
    
    ##Mount point
    mkdir /ebs
    mount /dev/RAID10/store /ebs
;;

'help'|'--h'|'-help')
    clear && printf "\nusage: $0 <instance|volumes>\n\n"
    echo "Press [enter] key to continue. . .";
    read enterKey
;;

*) clear && printf "\nusage: $0 <instance|volumes>\n\n"
    echo "Press [enter] key to continue. . .";
    read enterKey
;;

esac
