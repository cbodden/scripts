#!/bin/bash
#===============================================================================
#
#          FILE: multiboot.sh
#
#         USAGE: sudo ./multiboot.sh
#
#   DESCRIPTION: This script creates a multiboot usb disk with multiple os's.
#
#       OPTIONS: none yet
#  REQUIREMENTS: grub2, wget, linux, dosfstools
#          BUGS: probably a bunch, have not discovered yet.
#         NOTES: Tested on gentoo with gentoo's version of grub2.
#                If your distro automounts usb, this script will fail.
#        AUTHOR: cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 15 April 2014
#      REVISION: 10
#===============================================================================

LANG=C
set -e
set -o pipefail
set -o nounset
NAME=$(basename $0)
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

# check for sudo / root
R_UID="0"
[[ "${UID}" -ne "${R_UID}" ]] && { printf "\nNeeds sudo\n" ; exit 1 ; }

USBTMPDIR="/usbtmpdir"
GRUBCONF="${USBTMPDIR}/boot/grub/grub.cfg"

function disk_detect()
{
  typeset -r MAINPROMPT="Select a disk to use: "
  declare -a ARR=(`for DRIVE in $(fdisk -l | grep Disk |
    grep -v "Disklabel\|identifier" | awk '{print $2}' | cut -d: -f1);
    do echo $DRIVE ; done`)
  PS3=$MAINPROMPT
  clear
  select DRV in "${ARR[@]}"; do
    case "${DRV}" in
      ${DRV}) [[ -n $(df | grep "${DRV}") ]] &&
        { echo -e "${DRV} is used by:\n$(df | grep "${DRV}")"; exit 1; } ||
        { USBSTICK="${DRV}"; } ;;
    esac
    DRV_CLEAN=$(echo "${USBSTICK}" | cut -d"/" -f3)
    break
  done
}

function disk_action()
{
  ## do not touch this section or you break the fdisk function!!!
  dd if=/dev/zero of=${USBSTICK} bs=512 count=62
fdisk ${USBSTICK} <<EOF
d

d

d

d

n
p
1


t
c
a
w
EOF
  mkfs.vfat ${USBSTICK}1
}

function disk_grub2()
{
  mkdir ${USBTMPDIR}
  mount ${USBSTICK}1 ${USBTMPDIR}
  UUID=`ls -al /dev/disk/by-uuid/ | grep ${DRV_CLEAN}1 | awk '{print $9}'`
  [[ -n $(which grub2-install 2>/dev/null) ]] &&
    { grub2-install --no-floppy --root-directory=${USBTMPDIR} ${USBSTICK} ; } ||
    { grub-install --no-floppy --root-directory=${USBTMPDIR} ${USBSTICK} ; }
  mkdir ${USBTMPDIR}/iso/
}

function cleanup()
{
  sync
  umount ${USBSTICK}1
  rm ${USBTMPDIR} -rf
}

function install_grub_header()
{
echo "set timeout=300
set default=0
set menu_color_normal=white/black
set menu_color_highlight=white/green
" >> ${GRUBCONF}
}

function install_debian_amd64()
{
  VER="7.4.0"
  DL_ADDY="http://cdimage.debian.org/debian-cd/${VER}/amd64/iso-cd/"
  IMAGE="debian-${VER}-amd64-netinst.iso"

echo "menuentry \"Debian netinst ${VER} amd64\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"vga=normal --\"
  loopback loop \$isofile
  linux (loop)/install.amd/vmlinuz \$bo1
  initrd (loop)/install.amd/initrd.gz
}
" >> ${GRUBCONF}
  wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
}

function install_fedora()
{
  VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    [[ "$1" == "i386" ]] && { 3VER="i386" ; 6VER="i686" ; } ||
      { 3VER="$1" ; 6VER="$1" ; }
    DL_ADDY="mirror.pnl.gov/fedora/linux/releases/${VER}/Live/${3VER}/"
    IMAGE="Fedora-Live-Desktop-${6VER}-${VER}-1.iso"
    FED_OPTS="--class fedora --class gnu-linux --class gnu --class os"
echo "menuentry \"Fedora desktop ${VER} ${3VER}\" ${FED_OPTS} {
  insmod loopback
  set isolabel=Fedora-Live-Desktop-${6VER}-${VER}-1
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"iso-scan/filename=\$isofile\"
  set bo2=\"root=live:LABEL=\$isolabel ro rd.live.image quiet rhgb\"
  loopback loop (hd0,1)/\$isofile
  set root=(loop)
  linux /isolinux/vmlinuz0 \$bo1 \$bo2
  initrd /isolinux/initrd0.img
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_gentoo_amd64()
{
  VER="20140403"
  DL_ADDY="http://distfiles.gentoo.org/releases/amd64/autobuilds/${VER}/"
  IMAGE="install-amd64-minimal-${VER}.iso"

echo "menuentry \"Gentoo minimal ${VER} amd64\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"root=/dev/ram0 init=/linuxrc nokeymap cdroot cdboot\"
  set bo2=\"looptype=squashfs loop=/image.squashfs initrd=gentoo.igz\"
  set bo3=\"usbcore.autosuspend=1 console=tty0 rootdelay=10 isoboot=\$isofile\"
  loopback loop \$isofile
  linux (loop)/isolinux/gentoo \$bo1 \$bo2 \$bo3
  initrd (loop)/isolinux/gentoo.igz
}
" >> ${GRUBCONF}
  wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
}

function install_gentoo_i386()
{
  VER="20140415"
  DL_ADDY="http://distfiles.gentoo.org/releases/x86/autobuilds/${VER}/"
  IMAGE="install-x86-minimal-${VER}.iso"

echo "menuentry \"Gentoo minimal ${VER} i386\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"root=/dev/ram0 init=/linuxrc nokeymap cdroot cdboot\"
  set bo2=\"looptype=squashfs loop=/image.squashfs initrd=gentoo.igz\"
  set bo3=\"usbcore.autosuspend=1 console=tty0 rootdelay=10 isoboot=\$isofile\"
  loopback loop \$isofile
  linux (loop)/isolinux/gentoo \$bo1 \$bo2 \$bo3
  initrd (loop)/isolinux/gentoo.igz
}
" >> ${GRUBCONF}
  wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
}

function install_kali()
{
  VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    DL_ADDY="http://cdimage.kali.org/kali-latest/${1}/"
    IMAGE="kali-linux-${VER}-${1}.iso"

echo "menuentry \"Kali Linux ${VER} ${1}\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"findiso=\$isofile boot=live noconfig=sudo username=root\"
  set bo2=\"hostname=kali quiet splash\"
  search --set -f \$isofile
  loopback loop \$isofile
  linux (loop)/live/vmlinuz \$bo1 \$bo2
  initrd (loop)/live/initrd.img
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_netbsd()
{
  VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    DL_ADDY="mirror.planetunix.net/pub/NetBSD/NetBSD-${VER}/${1}/"
    KNL_DL="binary/kernel/netbsd-INSTALL.gz"
    KNL="netbsd-INSTALL.gz"
    ST="binary/sets/"
    WGET_OPTIONS="-r -l 1 -nd -e robots=off --reject *.html* --reject *.gif"
    WGET_PATH="--directory-prefix=${USBTMPDIR}/iso/netbsd/${VER}/${1}/"

echo "menuentry \"NetBSD ${VER} ${1}\" {
  insmod ext2
  set root=(hd0,msdos1)
  knetbsd /iso/netbsd/${VER}/${1}/${KNL}
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${ST} ${WGET_OPTIONS} ${WGET_PATH} || echo "NetBSD dloaded"
    wget ${DL_ADDY}${KNL_DL} ${WGET_PATH} || echo "NetBSD kernel dloaded"
    shift 1
  done
}

function install_openbsd()
{
  VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    DL_ADDY="http://openbsd.mirrors.hoobly.com/${VER}/${1}/"
    WGET_OPTIONS="-r -l 1 -nd -e robots=off --reject *.html* --reject *.gif"
    WGET_PATH="--directory-prefix=${USBTMPDIR}/${VER}/${1}/"

echo "menuentry \"OpenBSD ${VER} ${1}\" {
  insmod ext2
  set root=(hd0,msdos1)
  kopenbsd /${VER}/${1}/bsd.rd
}
" >> ${GRUBCONF}
    wget ${DL_ADDY} ${WGET_OPTIONS} ${WGET_PATH} || echo "OpenBSD dloaded"
    shift 1
  done
}

function install_tails()
{
  VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    DL_ADDY="http://dl.amnesia.boum.org/tails/stable/tails-${1}-${VER}/"
    IMAGE="tails-${1}-${VER}.iso"

echo "menuentry \"Tails ${VER} ${1} default\" {
  set isofile=\"/iso/${IMAGE}\"
  set isouuid=\"/dev/disk/by-uuid/${UUID}/iso/${IMAGE}\"
  set bo1=\"boot=live config\"
  loopback loop \$isofile
  linux (loop)/live/vmlinuz fromiso=\$isouuid \$bo1
  initrd (loop)/live/initrd.img
}
" >> ${GRUBCONF}

echo "menuentry \"Tails ${VER} ${1} masquerade\" {
  set isofile=\"/iso/${IMAGE}\"
  set isouuid=\"/dev/disk/by-uuid/${UUID}/iso/${IMAGE}\"
  set bo1=\"boot=live config live-media=removable nopersistent noprompt quiet\"
  set bo2=\"timezone=Etc/UTC block.events_dfl_poll_msecs=1000 splash\"
  set bo3=\"nox11autologin module=Tails truecrypt quiet\"
  loopback loop \$isofile
  linux (loop)/live/vmlinuz fromiso=\$isouuid \$bo1 \$bo2 \$bo3
  initrd (loop)/live/initrd.img
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_ubuntu12s_amd64()
{
  DL_ADDY="http://releases.ubuntu.com/12.04.4/"
  IMAGE="ubuntu-12.04.4-server-amd64.iso"

echo "menuentry \"Ubuntu 12.04 server amd64\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"boot=casper iso-scan/filename=\$isofile noprompt noeject\"
  loopback loop (hd0,1)\$isofile
  linux (loop)/casper/vmlinuz.efi \$bo1
  initrd (loop)/casper/initrd.lz
}
" >> ${GRUBCONF}
  wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
}

function install_ubuntu13d_amd64()
{
  DL_ADDY="http://releases.ubuntu.com/13.10/"
  IMAGE="ubuntu-13.10-desktop-amd64.iso"

echo "menuentry \"Ubuntu 13.10 desktop amd64\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"boot=casper iso-scan/filename=\$isofile noprompt noeject\"
  loopback loop (hd0,1)\$isofile
  linux (loop)/casper/vmlinuz.efi \$bo1
  initrd (loop)/casper/initrd.lz
}
" >> ${GRUBCONF}
  wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
}

function install_ubuntu13d_i386()
{
  DL_ADDY="http://releases.ubuntu.com/13.10/"
  IMAGE="ubuntu-13.10-desktop-i386.iso"

echo "menuentry \"Ubuntu 13.10 desktop i386\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"boot=casper iso-scan/filename=\$isofile noprompt noeject\"
  loopback loop (hd0,1)\$isofile
  linux (loop)/casper/vmlinuz \$bo1
  initrd (loop)/casper/initrd.lz
}
" >> ${GRUBCONF}
  wget ${DL_ADDY}${IMAGE}  --directory-prefix=${USBTMPDIR}/iso/
}

#### functions to run below this line ####

disk_detect
disk_action
disk_grub2
install_grub_header
install_debian_amd64
install_fedora 20 x86_64 i386
install_gentoo_amd64
install_gentoo_i386
install_kali 1.0.6 amd64
install_netbsd 6.1.3 amd64 i386
install_openbsd 5.4 amd64 i386
install_tails 0.23 i386
install_ubuntu12s_amd64
install_ubuntu13d_amd64
install_ubuntu13d_i386
cleanup
