#!/usr/bin/env bash
#===============================================================================
#
#          FILE: uefi_kernel_install.sh
#         USAGE: ./uefi_kernel_install.sh
#
#   DESCRIPTION: this script assists with adding a new kernel to efi stub,
#                installing the new linux firmware,
#                and rebooting into the new kern with kexec
#       OPTIONS: -f, -k, -p
#  REQUIREMENTS: efibootmgr, dracut, lsblk, kexec, elinks, tar
#          BUGS: none so far
#         NOTES: use wisely
#        AUTHOR: Cesar Bodden (), cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 08/25/2018 08:32:56 PM EDT
#      REVISION: 9
#===============================================================================

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

    readonly PROGNAME=$(basename $0)
    readonly PROGDIR=$(readlink -m $(dirname $0))
    readonly BZIMG="/arch/x86/boot/bzImage"
    readonly BOOT="/boot/EFI/gentoo/"
    readonly KERN_PATH=$(readlink -f /usr/src/linux)
    readonly KERN_VER=$(basename ${KERN_PATH})
    readonly KERN_VER_FULL=$(file ${KERN_PATH}${BZIMG} \
                 | awk '{print $9}')
    clear
}

function _Dep()
{
    local _DEPS=""
    while [ $# -gt 0 ]
    do
        _DEPS="${_DEPS} $1"
        shift
    done

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
}

function _Maj()
{
    readonly DISKMAJ=$(${LSBLK} -a -p -l \
                 | awk '/\/boot/')
    readonly DISK=$(echo ${DISKMAJ} \
                 | awk '{print $1}')
    readonly MAJ=$(echo ${DISKMAJ} \
                 | awk '{print $1}' \
                 | tail -c 2 )
}

function _Pause()
{
    if [ "${_PCHOICE}" == "enable" ]
    then
        printf "%s\n" \
            "${GRN_F}. . . .Press enter to continue. . . .${CLR}"
        read -p "$*"
    fi
}

function _Timer()
{
    local _SPINNER=( '|' '/' '-' '\' );
    local _MAX=$((SECONDS + 10))

    while [[ ${SECONDS} -le ${_MAX} ]]
    do
        for ITER in ${_SPINNER[*]}
        do
            printf "\r${ITER}"
            sleep .075
            printf "\r \r"
        done
    done
}

function _Version()
{
    printf "%s\n" \
        "${BLU_F}This script will install " \
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
        --force --hostonly --xz \
        &>/dev/null
}

function _Clear_Old_Boot()
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

function _Install_New_Boot()
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

function _Firmware()
{
    readonly GITLAB="https://gitlab.com/kernel-firmware/linux-firmware"
    readonly TAGS="${GITLAB}/-/tags"
    readonly ARCHIVE="${GITLAB}/-/archive/"

    local _LINK=$(${ELINKS} -dump ${TAGS} \
        | grep -m 1 "/tags/")
    local _VER=${_LINK##*/}
    local _DLOAD_VER="${_VER}/linux-firmware-${_VER}"

    printf "%s\n" \
        "${BLU_F}Creating and switching to TMP (/tmp/${_VER})" \
        "${RED_F}mkdir /tmp/${_VER}/ ; cd /tmp/${_VER}/" \
        "${CLR}"
    mkdir /tmp/${_VER}/
    cd /tmp/${_VER}/

    printf "%s\n" \
        "${BLU_F}Downloading Version  : ${RED_F}${_DLOAD_VER##*/}" \
        "${RED_F}${WGET} ${ARCHIVE}${_DLOAD_VER}.tar.gz -q --show-progress" \
        "${CLR}"
    ${WGET} ${ARCHIVE}${_DLOAD_VER}.tar.gz -q --show-progress

    printf "%s\n" "" \
        "${BLU_F}Uncompressing ${_DLOAD_VER##*/}" \
        "${RED_F}${TAR} -xzf ${_DLOAD_VER##*/}.tar.gz" \
        "${CLR}"
    ${TAR} -xzf ${_DLOAD_VER##*/}.tar.gz

    printf "%s\n" \
        "${BLU_F}Copying ${_DLOAD_VER##*/} to /lib/firmware/" \
        "${RED_F}cp -r ${_DLOAD_VER##*/}/* /lib/firmware/" \
        "${CLR}"
    cp -r ${_DLOAD_VER##*/}/* /lib/firmware/

    printf "%s\n" \
        "${BLU_F}Removing TMP dir" \
        "${RED_F}rm -rf /tmp/${_VER}/" \
        "${CLR}"
    rm -rf /tmp/${_VER}/
}

function _Kexec()
{
    local _P0="${KEXEC}"
    local _P1=" -l "
    local _P2="--append=\"`cat /proc/cmdline \
        | awk '{print $1}'` "
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
        ". . . . REBOOTING IN 10 SECONDS. . . .${CLR}"
    _Timer
    ${KEXEC} -e
}

function usage()
{
    ## usage / description function
    clear
    echo -e "
    NAME
        ${PROGNAME} - EFI stub kernel installer

    SYNOPSIS
        ${PROGNAME} [OPTION]...

    DESCRIPTION
        ${PROGNAME} will install a newly compiled kernel to the EFI stub
        on the local machine.
        It has options to download the latet linux firmware files and also
        an option to reboot with Kexec after kernel is installed. 

    OPTIONS
        -f [0|1]
                This option enables / disables the firmware download.
                This option is required.
                0 = Disable
                1 = Enable

        -k
                This option sets kexec reboot.
                Default is disabled.

        -p
                This option sets pause after every item.
                Default is disabled.
    "
}

#################################
#### begin non function area ####
#################################

LC_ALL=C
LANG=C
set -e
set -o nounset
set -o pipefail
set -u
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

main

unset -v _FCHOICE
_KCHOICE="exit 0"
_PCHOICE="disable"

## option selection
while getopts ":f:kp" OPT
do
    case "${OPT}" in
        'f')
            if [ ${OPTARG} == 1 ]
            then
                _FCHOICE="_Firmware"
            else
                _FCHOICE="echo"
            fi
            ;;
        'k')
            _KCHOICE="_Kexec"
            ;;
        'p')
            _PCHOICE="enable"
            ;;
        *)
            usage \
                | less
            exit 0
            ;;
    esac
done
if [[ ${OPTIND} -eq 1 ]]
then
    usage \
        | less
    exit 0
fi
shift $((OPTIND-1))

if [ -z "${_FCHOICE}" ]
then
    usage \
        | less
    exit 0
fi

_Dep mount dracut efibootmgr lsblk kexec elinks wget tar
_Version
_Maj
_RW_efivars
_Kernel_to_Boot
_Make_initramfs
_Clear_Old_Boot
_Install_New_Boot
_RO_efivars
${_FCHOICE}
${_KCHOICE}
