#!/usr/bin/env bash
#===============================================================================
#
#          FILE: uefi_kernel_install.sh
#         USAGE: ./uefi_kernel_install.sh
#
#   DESCRIPTION: this script assists with adding a new kernel to efi stub
#       OPTIONS: none
#  REQUIREMENTS: efibootmgr, sudo, dracut, lsblk
#          BUGS: none so far
#         NOTES: use wisely
#        AUTHOR: Cesar Bodden (), cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 08/25/2018 08:32:56 PM EDT
#      REVISION: 3
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
    readonly NAME=$(basename $0)
    readonly BZIMG="/arch/x86/boot/bzImage"
    readonly BOOT="/boot/EFI/gentoo/"
    readonly KERN_PATH=$(readlink -f /usr/src/linux)
    readonly KERN_VER=$(basename ${KERN_PATH})
    readonly KERN_VER_FULL=$(file ${KERN_PATH}${BZIMG} \
                 | awk '{print $9}')
    readonly DISKMAJ=$(sudo lsblk -a -p -l \
                 | awk '/\ \/boot/')
    readonly DISK=$(echo ${DISKMAJ} \
                 | awk '{print $1}')
    readonly MAJ=$(echo ${DISKMAJ} \
                 | awk '{print $2}' \
                 | cut -d: -f2)
    readonly RED=$(tput setaf 1)
    readonly BLU=$(tput setaf 4)
    readonly GRN=$(tput setaf 40)
    readonly CLR=$(tput sgr0)
    clear
}

function _Pause()
{
    printf "%s\n" \
        "${GRN}. . . .Press enter to continue. . . .${CLR}"
    read -p "$*"
}

function _TestVars()
{
    clear
    printf "%s\n" \
        "${BLU}Kernel Path          : ${RED}${KERN_PATH}" \
        "${BLU}Kernel Version       : ${RED}${KERN_VER}" \
        "${BLU}Kernel Version Full  : ${RED}${KERN_VER_FULL}" \
        "${CLR}"
    _Pause
}

function _RW_efivars()
{
    printf "%s\n" \
        "${BLU}Now mounting /sys/firmware/efi/efivars read write" \
        "${RED}sudo mount /sys/firmware/efi/efivars -o rw,remount" \
        "${CLR}"
    _Pause
    sudo mount /sys/firmware/efi/efivars -o rw,remount
}

function _Kernel_to_Boot()
{
    printf "%s\n" \
        "${BLU}Now copying ${KERN_VER_FULL} to ${BOOT}" \
        "${RED}cp ${KERN_PATH}${BZIMG} ${BOOT}bzImage-${KERN_VER_FULL}.efi" \
        "${CLR}"
    _Pause
    sudo cp ${KERN_PATH}${BZIMG} ${BOOT}bzImage-${KERN_VER_FULL}.efi
}

function _Make_initramfs()
{
    printf "%s\n" \
        "${BLU}Now generating ${BOOT}initramfs-${KERN_VER_FULL}.img" \
        "${RED}sudo dracut ${BOOT}initramfs-${KERN_VER_FULL}.img" \
        "${CLR}"
    _Pause
    sudo dracut ${BOOT}initramfs-${KERN_VER_FULL}.img
}

function _Clear_Old_Boot
{
    local _UEFI_OBJ=$(sudo efibootmgr \
        | awk '/[Gg]entoo/ {print substr($1, 0, length($1)-1)}')
    printf "%s\n" \
        "${RED}Now clearing the default boot from efibootmgr" \
        "${CLR}"
    _Pause
    for ITER in ${_UEFI_OBJ}
    do
        sudo efibootmgr -b ${ITER#Boot} -B
    done
}

function _Install_New_Boot
{
    local _P0="/usr/sbin/efibootmgr"
    local _P1=" -c -d ${DISK}"
    local _P2=" -p ${MAJ} -L \"Gentoo ${KERN_VER_FULL}\""
    local _P3=" -l '\EFI\gentoo\bzImage-${KERN_VER_FULL}.efi'"
    local _P4=" -u 'initrd=\EFI\gentoo\initramfs-${KERN_VER_FULL}.img'"
    printf "%s\n" \
        "${BLU}Now installing the new kernel and initramfs to UEFI" \
        "${RED}${_P0}${_P1}${_P2}${_P3}${_P4}" \
        "${CLR}"
    _Pause
    eval sudo ${_P0}${_P1}${_P2}${_P3}${_P4}
}

function _RO_efivars()
{
    printf "%s\n" \
        "${BLU}Now mounting /sys/firmware/efi/efivars read only" \
        "${RED}sudo mount /sys/firmware/efi/efivars -o ro,remount" \
        "${CLR}"
    _Pause
    sudo mount /sys/firmware/efi/efivars -o ro,remount
}

main
_Pause
_TestVars
_RW_efivars
_Kernel_to_Boot
_Make_initramfs
_Clear_Old_Boot
_Install_New_Boot
_RO_efivars
