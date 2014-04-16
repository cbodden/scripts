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
#       CREATED: 04/15/2014
#      REVISION: 7
#===============================================================================

LANG=C
set -e
set -o pipefail
set -o nounset
# set -o errexit
NAME=$(basename $0)
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

# check for sudo / root
R_UID="0"
[[ "${UID}" -ne "${R_UID}" ]] && { printf "\nNeeds sudo\n" ; exit 1 ; }

VOLNAME="MultiBoot"
USBTMPDIR="usbtmpdir"
GRUBCONF="/${USBTMPDIR}/boot/grub/grub.conf"

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
  UUID=`ls -al /dev/disk/by-uuid/ | grep ${DRV_CLEAN}1 | awk '{print $9}'`
  break
  done
}

function disk_action()
{
dd if=/dev/zero of=${USBSTICK} bs=512 count=62
## do not touch the next couple of lines or you break fdisk!!!
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
  # mkfs.vfat -n ${VOLNAME} /dev/${USBSTICK}1
  mkfs.vfat ${USBSTICK}1
}

function grub2()
{
  ## begin grub2 stuff
  mkdir /${USBTMPDIR}
  mount ${USBSTICK}1 /${USBTMPDIR}
  grub2-install --no-floppy --root-directory=/${USBTMPDIR} ${USBSTICK}
  mkdir /${USBTMPDIR}/iso/
}

function cleanup()
{
  sync
  umount ${USBSTICK}1
  rm /${USBTMPDIR} -rf
}

function grub_header()
{
echo "set timeout=300
set default=0
set menu_color_normal=white/black
set menu_color_highlight=white/green
" >> ${GRUBCONF}
}

function debian_amd64()
{
DL_ADDY=""
IMAGE=""

echo "menuentry \"Debian netinst 7.4.0 amd64\" {
  set isofile=\"/iso/debian-7.4.0-amd64-netinst.iso\"
  set bo1=\"vga=normal --\"
  loopback loop \$isofile
  linux (loop)/install.amd/vmlinuz \$bo1
  initrd (loop)/install.amd/initrd.gz
}
" >> ${GRUBCONF}
}

function gentoo_amd64()
{
DL_ADDY="http://distfiles.gentoo.org/releases/amd64/autobuilds/20140403/"
IMAGE="install-amd64-minimal-20140403.iso"

echo "menuentry \"Gentoo minimal 20140403 amd64\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"root=/dev/ram0 init=/linuxrc nokeymap cdroot cdboot\"
  set bo2=\"looptype=squashfs loop=/image.squashfs initrd=gentoo.igz\"
  set bo3=\"usbcore.autosuspend=1 console=tty0 rootdelay=10 isoboot=\$isofile\"
  loopback loop \$isofile
  linux (loop)/isolinux/gentoo \$bo1 \$bo2 \$bo3
  initrd (loop)/isolinux/gentoo.igz
}
" >> ${GRUBCONF}
wget ${DL_ADDY}${IMAGE}  --directory-prefix=/${USBTMPDIR}/iso/
}

function gentoo_i386()
{
DL_ADDY="http://distfiles.gentoo.org/releases/x86/autobuilds/20140415/"
IMAGE="install-x86-minimal-20140415.iso"

echo "menuentry \"Gentoo minimal 20140415 i386\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"root=/dev/ram0 init=/linuxrc nokeymap cdroot cdboot\"
  set bo2=\"looptype=squashfs loop=/image.squashfs initrd=gentoo.igz\"
  set bo3=\"usbcore.autosuspend=1 console=tty0 rootdelay=10 isoboot=\$isofile\"
  loopback loop \$isofile
  linux (loop)/isolinux/gentoo \$bo1 \$bo2 \$bo3
  initrd (loop)/isolinux/gentoo.igz
}
" >> ${GRUBCONF}
wget ${DL_ADDY}${IMAGE}  --directory-prefix=/${USBTMPDIR}/iso/
}

function kali_amd64()
{
DL_ADDY="http://cdimage.kali.org/kali-latest/amd64/"
IMAGE="kali-linux-1.0.6-amd64.iso"

echo "menuentry \"Kali Linux 1.0.6 amd64\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"findiso=\$isofile boot=live noconfig=sudo username=root\"
  set bo2=\"hostname=kali quiet splash\"
  search --set -f \$isofile
  loopback loop \$isofile
  linux (loop)/live/vmlinuz \$bo1 \$bo2
  initrd (loop)/live/initrd.img
}
" >> ${GRUBCONF}
wget ${DL_ADDY}${IMAGE}  --directory-prefix=/${USBTMPDIR}/iso/
}

function netbsd_i386()
{
echo "menuentry \"NetBSD 6.1.3 i386\" {
  set isofile="/iso/NetBSD-6.1.3-i386.iso"
  set root=(hd0,msdos1)
  loopback loop \$isofile
  insmod ext2
  knetbsd /boot
}
" >> ${GRUBCONF}
}

function openbsd54_amd64()
{
DL_ADDY="http://ftp.openbsd.org/pub/OpenBSD/5.4/amd64/"
WGET_OPTIONS="-r -l 1 -nd -e robots=off --reject index.html"
WGET_PATH="--directory-prefix=/${USBTMPDIR}5.4/amd64/"

echo "menuentry \"OpenBSD 5.4 amd64\" {
  insmod ext2
  set root=(hd0,msdos1)
  kopenbsd /5.4/amd64/bsd.rd
}
" >> ${GRUBCONF}
wget -nd -r ${DL_ADDY} ${WGET_OPTIONS} ${WGET_PATH}
}

function openbsd54_i386()
{
DL_ADDY="http://ftp.openbsd.org/pub/OpenBSD/5.4/i386/"
WGET_OPTIONS="-r -l 1 -nd -e robots=off --reject index.html"
WGET_PATH="--directory-prefix=/${USBTMPDIR}5.4/i386/"

echo "menuentry \"OpenBSD 5.4 i386\" {
  insmod ext2
  set root=(hd0,msdos1)
  kopenbsd /5.4/i386/bsd.rd
}
" >> ${GRUBCONF}
wget -nd -r ${DL_ADDY} ${WGET_OPTIONS} ${WGET_PATH}
}

function tails_i386()
{
DL_ADDY="http://dl.amnesia.boum.org/tails/stable/tails-i386-0.23/"
IMAGE="tails-i386-0.23.iso"

echo "menuentry \"Tails 0.23 i386\" {
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
wget ${DL_ADDY}${IMAGE}  --directory-prefix=/${USBTMPDIR}/iso/
}

function ubuntu12s_amd64()
{
DL_ADDY="http://releases.ubuntu.com/12.04.4/"
IMAGE="ubuntu-12.04.4-server-amd64.iso"

echo "menuentry \"Ubuntu 12.04 server amd64\" {
  set isofile=\"/iso/i${IMAGE}\"
  set bo1=\"boot=casper iso-scan/filename=\$isofile noprompt noeject\"
  loopback loop (hd0,1)\$isofile
  linux (loop)/casper/vmlinuz.efi \$bo1
  initrd (loop)/casper/initrd.lz
}
" >> ${GRUBCONF}
wget ${DL_ADDY}${IMAGE}  --directory-prefix=/${USBTMPDIR}/iso/
}

function ubuntu13d_amd64()
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
wget ${DL_ADDY}${IMAGE}  --directory-prefix=/${USBTMPDIR}/iso/
}

function ubuntu13d_i386()
{
DL_ADDY="http://releases.ubuntu.com/13.10/"
IMAGE="ubuntu-13.10-desktop-i386.iso"

echo "menuentry \"Ubuntu 13.10 desktop i386\" {
  set isofile=\"/iso/ubuntu-13.10-desktop-i386.iso\"
  set bo1=\"boot=casper iso-scan/filename=\$isofile noprompt noeject\"
  loopback loop (hd0,1)\$isofile
  linux (loop)/casper/vmlinuz \$bo1
  initrd (loop)/casper/initrd.lz
}
" >> ${GRUBCONF}
wget ${DL_ADDY}${IMAGE}  --directory-prefix=/${USBTMPDIR}/iso/
}

#### functions to run below this line ####

disk_detect
disk_action
grub2
grub_header
## debian_amd64
gentoo_amd64
## gentoo_i386
## kali_amd64
## netbsd_i386
## openbsd54_amd64
## openbsd54_i386
## tails_i386
## ubuntu12s_amd64
## ubuntu13d_amd64
## ubuntu13d_i386
cleanup
