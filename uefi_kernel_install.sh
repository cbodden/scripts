#!/usr/bin/env bash
#===============================================================================
#
#          FILE: uefi_kernel_install.sh
#         USAGE: ./uefi_kernel_install.sh
#
#   DESCRIPTION: this script assists with adding a new kernel to uefi
#       OPTIONS: none
#  REQUIREMENTS: efibootmgr, sudo, dracut
#          BUGS: none so far
#         NOTES: use wisely
#        AUTHOR: Cesar Bodden (), cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 08/25/2018 08:32:56 PM EDT
#      REVISION: 1
#===============================================================================

LC_ALL=C
LANG=C
set -o nounset
set -o pipefail
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

function main()
{
    NAME=$(basename $0)
    BZIMG="/arch/x86/boot/bzImage"
    BOOT="/boot/EFI/gentoo/"
    KERN_PATH=$(readlink -f /usr/src/linux)
    KERN_VER=$(basename ${KERN_PATH})
    KERN_VER_FULL=$(file ${KERN_PATH}${BZIMG} \
        | awk '{print $9}')
    _RED=$(tput setaf 1)
    _BLU=$(tput setaf 4)
    _GRN=$(tput setaf 40)
    _CLR=$(tput sgr0)
    clear
}

function pause()
{
    printf "%s\n" \
        "${_GRN}Press enter to continue. . . .${_CLR} "
    read -p "$*"
}

function _testVars()
{
    clear
    printf "%s\n" \
        "${_BLU}Kernel Path          : ${_RED}${KERN_PATH}" \
        "${_BLU}Kernel Version       : ${_RED}${KERN_VER}" \
        "${_BLU}Kernel Version Full  : ${_RED}${KERN_VER_FULL}" \
        "${_CLR}"
    pause
}

function _rw_efivars()
{
    printf "%s\n" \
        "${_BLU}Now mounting /sys/firmware/efi/efivars read write" \
        "${_RED}sudo mount /sys/firmware/efi/efivars -o rw,remount" \
        "${_CLR}"
    pause
    sudo mount /sys/firmware/efi/efivars -o rw,remount
}

function _kernel_to_boot()
{
    printf "%s\n" \
        "${_BLU}Now copying ${KERN_VER_FULL} to ${BOOT}" \
        "${_RED}cp ${KERN_PATH}${BZIMG} ${BOOT}bzimage-${KERN_VER_FULL}.efi" \
        "${_CLR}"
    pause
    sudo cp ${KERN_PATH}${BZIMG} ${BOOT}bzimage-${KERN_VER_FULL}.efi
}

function _make_initramfs()
{
    printf "%s\n" \
        "${_BLU}Now generating ${BOOT}initramfs-${KERN_VER_FULL}.img" \
        "${_RED}sudo dracut ${BOOT}initramfs-${KERN_VER_FULL}.img" \
        "${_CLR}"
    pause
    sudo dracut ${BOOT}initramfs-${KERN_VER_FULL}.img
}

function _clear_old_boot
{
    printf "%s\n" \
        "${_BLU}Now clearing the default boot from efibootmgr" \
        "${_RED}sudo efibootmgr -b 0000 -B" \
        "${_CLR}"
    pause
    sudo efibootmgr -b 0000 -B
}

function _install_new_boot
{
    _BOOT_PARAM="
        --create \
        --part 0 \
        --label Gentoo ${KERN_VER_FULL} \
        --loader '\EFI\gentoo\bzimage-${KERN_VER_FULL}.efi' \
        --unicode 'initrd=\EFI\gentoo\initramfs-${KERN_VER_FULL}.img'"
    printf "%s\n" \
        "${_BLU}Now writing new UEFI boot entry" \
        "${_RED}sudo efibootmgr${_BOOT_PARAM}" \
        "${_CLR}"
    pause
    sudo efibootmgr ${_BOOT_PARAM}
}

function _ro_efivars()
{
    printf "%s\n" \
        "${_BLU}Now mounting /sys/firmware/efi/efivars read only" \
        "${_RED}sudo mount /sys/firmware/efi/efivars -o ro,remount" \
        "${_CLR}"
    pause
    sudo mount /sys/firmware/efi/efivars -o ro,remount
}

main
pause
# _testVars
_rw_efivars
_kernel_to_boot
_make_initramfs
_clear_old_boot
_install_new_boot
_ro_efivars
