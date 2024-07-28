#!/usr/bin/env bash
#===============================================================================
#
#          FILE: uefi_kernel_install.sh
#         USAGE: ./uefi_kernel_install.sh
#
#   DESCRIPTION: this script assists with adding a new kernel to efi stub
#                and also rebooting into the new kern with kexec
#       OPTIONS: none
#  REQUIREMENTS: efibootmgr, dracut, lsblk, kexec
#          BUGS: none so far
#         NOTES: use wisely
#        AUTHOR: Cesar Bodden (), cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 08/25/2018 08:32:56 PM EDT
#      REVISION: 4
#===============================================================================

LC_ALL=C
LANG=C
set -e
set -o nounset
set -o pipefail
set -u
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

function main()
{
    readonly RED_F=$(tput setaf 1)
    readonly BLU_F=$(tput setaf 4)
    readonly GRN_F=$(tput setaf 40)
    readonly RED_B=$(tput setab 1)
    readonly BLU_B=$(tput setab 4)
    readonly GRN_B=$(tput setab 40)
    readonly BLINK=$(tput blink)
    readonly CLR=$(tput sgr0)

    local _R_UID="0"
    if [ "${UID}" -ne "${_R_UID}" ]
    then
        printf "%s\n" \
            "${RED_F}. . .Needs sudo. . .${CLR}"
        exit 1
    fi

    local _DEPS="mount dracut efibootmgr lsblk"
    for ITER in ${_DEPS}
    do
        if [ -z "$(which ${ITER} 2>/dev/null)" ]
        then
            printf "%s\n" \
                "${RED_F}. . .${ITER} not found. . .${CLR}"
            exit 1
        else
            readonly ${ITER^^}="$(which ${ITER})"
        fi
    done

    readonly NAME=$(basename $0)
    readonly BZIMG="/arch/x86/boot/bzImage"
    readonly BOOT="/boot/EFI/gentoo/"
    readonly KERN_PATH=$(readlink -f /usr/src/linux)
    readonly KERN_VER=$(basename ${KERN_PATH})
    readonly KERN_VER_FULL=$(file ${KERN_PATH}${BZIMG} \
                 | awk '{print $9}')
    readonly DISKMAJ=$(${LSBLK} -a -p -l \
                 | awk '/\/boot/')
    readonly DISK=$(echo ${DISKMAJ} \
                 | awk '{print $1}')
    readonly MAJ=$(echo ${DISKMAJ} \
                 | awk '{print $1}' \
                 | tail -c 2 )
                 #| awk '{print $2}' \
                 #| cut -d: -f2)
    clear
}

function _Pause()
{
    printf "%s\n" \
        "${GRN_F}. . . .Press enter to continue. . . .${CLR}"
    read -p "$*"
}

function _Timer()
{
    readonly _SPINNER=( '|' '/' '-' '\' );
    readonly _MAX=$((SECONDS + 10))

    while [[ ${SECONDS} -le ${_MAX} ]]
    do
        for ITER in ${_SPINNER[*]}
        do
            echo -en "\r${ITER}"
            sleep .1
            echo -en "\r              \r"
        done
    done
}

function _Menu
{
    while :
    do
        printf "%s\n" \
            "${BLU_F}This script will install " \
            "${BLU_F}Kernel Version       : ${RED_F}${KERN_VER}" \
            "${BLU_F}Kernel Version Full  : ${RED_F}${KERN_VER_FULL}" ""\
            "${BLU_F}Do you want to reboot when kernel is installed ??${GRN_F}"
        read -p "(${RED_F}Y${GRN_F})es or (${RED_F}N${GRN_F})o : " _KCHOICE
        case ${_KCHOICE} in
            [yY][eE][sS]|[yY])
                printf "%s\n" \
                    "" "${BLU_F}Will reboot into new kernel with kexec" ""
                readonly _CHOICE=_Kexec
                break
                ;;
            [nN][oO]|[nN])
                printf "%s\n" \
                    "" "${BLU_F}Will not reboot into new kernel" ""
                readonly _CHOICE=_Pause
                break
                ;;
            * )
                printf "%s\n" \
                    ${RED_F}"Please answer Yes or No."
                clear
                ;;
        esac
    done
}

function _TestVars()
{
    clear
    printf "%s\n" \
        "${BLU_F}Kernel Path          : ${RED_F}${KERN_PATH}" \
        "${BLU_F}Kernel Version       : ${RED_F}${KERN_VER}" \
        "${BLU_F}Kernel Version Full  : ${RED_F}${KERN_VER_FULL}" \
        "${CLR}"
    _Pause
}

function _RW_efivars()
{
    printf "%s\n" \
        "${BLU_F}Now mounting /sys/firmware/efi/efivars read write" \
        "${RED_F}${MOUNT} /sys/firmware/efi/efivars -o rw,remount" \
        "${CLR}"
    _Pause
    ${MOUNT} /sys/firmware/efi/efivars -o rw,remount
}

function _Kernel_to_Boot()
{
    printf "%s\n" \
        "${BLU_F}Now copying ${KERN_VER_FULL} to ${BOOT}" \
        "${RED_F}cp ${KERN_PATH}${BZIMG} ${BOOT}bzImage-${KERN_VER_FULL}.efi" \
        "${CLR}"
    _Pause
    cp ${KERN_PATH}${BZIMG} ${BOOT}bzImage-${KERN_VER_FULL}.efi
}

function _Make_initramfs()
{
    printf "%s\n" \
        "${BLU_F}Now generating ${BOOT}initramfs-${KERN_VER_FULL}.img" \
        "${RED_F}${DRACUT} ${BOOT}initramfs-${KERN_VER_FULL}.img" \
        "${CLR}"
    _Pause
    ${DRACUT} ${BOOT}initramfs-${KERN_VER_FULL}.img \
        --force --hostonly \
        &>/dev/null
}

function _Clear_Old_Boot
{
    local _UEFI_OBJ=$(${EFIBOOTMGR} \
        | awk '/[Gg]entoo/ {print substr($1, 0, length($1)-1)}')
    printf "%s\n" \
        "${RED_F}Now clearing the default boot from efibootmgr" \
        "${CLR}"
    _Pause
    for ITER in ${_UEFI_OBJ}
    do
        ${EFIBOOTMGR} -b ${ITER#Boot} -B
    done
}

function _Install_New_Boot
{
    local _P0="${EFIBOOTMGR}"
    local _P1=" -c -d ${DISK}"
    local _P2=" -p ${MAJ} -L \"Gentoo ${KERN_VER_FULL}\""
    local _P3=" -l '\EFI\gentoo\bzImage-${KERN_VER_FULL}.efi'"
    local _P4=" -u 'initrd=\EFI\gentoo\initramfs-${KERN_VER_FULL}.img'"
    printf "%s\n" \
        "${BLU_F}Now installing the new kernel and initramfs to UEFI" \
        "${RED_F}${_P0}${_P1}${_P2}${_P3}${_P4}" \
        "${CLR}"
    _Pause
    eval ${_P0}${_P1}${_P2}${_P3}${_P4}
}

function _RO_efivars()
{
    printf "%s\n" \
        "${BLU_F}Now mounting /sys/firmware/efi/efivars read only" \
        "${RED_F}${MOUNT} /sys/firmware/efi/efivars -o ro,remount" \
        "${CLR}"
    _Pause
    ${MOUNT} /sys/firmware/efi/efivars -o ro,remount
}

function _Kexec
{
    local _DEPS="kexec"
    for ITER in ${_DEPS}
    do
        if [ -z "$(which ${ITER} 2>/dev/null)" ]
        then
            printf "%s\n" \
                "${RED_F}. . .${ITER} not found. . .${CLR}"
            exit 1
        else
            readonly ${ITER^^}="$(which ${ITER})"
        fi
    done

    local _P0="${KEXEC}"
    local _P1=" -l "
    local _P2="--append=\"`cat /proc/cmdline | awk '{print $1}'` "
    local _P3="initrd='\EFI\gentoo\initramfs-${KERN_VER_FULL}.img'\" "
    local _P4="/boot/EFI/gentoo/bzImage-${KERN_VER_FULL}.efi "
    printf "%s\n" \
        "${BLU_F}Now running kexec with the new kernel" \
        "${RED_F}${_P0}${_P1}${_P2}${_P3}${_P4}" \
        "${CLR}"
    _Pause
    eval ${_P0}${_P1}${_P2}${_P3}${_P4}
    sync
    printf "%s\n" \
        "" "${RED_B}${BLU_F}${BLINK}" \
        ". . . . REBOOTING IN 10 SECONDS. . . ." "${CLR}"
    _Timer
    ${KEXEC} -e
}


main
_Menu
## _TestVars
_RW_efivars
_Kernel_to_Boot
_Make_initramfs
_Clear_Old_Boot
_Install_New_Boot
_RO_efivars
${_CHOICE}
