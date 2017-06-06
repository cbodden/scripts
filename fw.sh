#!/usr/bin/env bash
#===============================================================================
#
#          FILE: fw.sh
#
#         USAGE: ./fw.sh
#
#   DESCRIPTION: iptables script for portability
#
#       OPTIONS: none yet
#  REQUIREMENTS: iptables, ip6tables, sudo
#          BUGS: most likely
#         NOTES: this is a huge work in progress
#        AUTHOR: Cesar Bodden (), cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 06/05/2017 11:17:07 PM EDT
#      REVISION:  ---
#===============================================================================

set -o nounset

_WINT=$(ifconfig \
    | grep "^[a-z]" \
    | grep -v "^lo\|^sit\|tun" \
    | awk '{print $1}' \
    | tr -d ":" )

_IPT="sudo /sbin/iptables"
_IP6T="sudo /sbin/ip6tables"

# do not accept ssr or lsr
# disable icmp redirected packets
_0_ITER="/proc/sys/net/ipv4/conf/*/accept_source_route
/proc/sys/net/ipv4/conf/*/accept_redirects"

for ITER in ${_0_ITER}
do
    echo 0 \
        | sudo tee ${ITER}
done

# do not reply to broadcast ping
# do not reply to SYN
_1_ITER="/proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
/proc/sys/net/ipv4/conf/*/rp_filter"

for ITER in ${_1_ITER}
do
    echo 1 \
        | sudo tee ${ITER}
done

# clear iptables
${_IPT} -F

# allow anything on localhost
${_IPT} -A INPUT  -i lo -j ACCEPT
${_IPT} -A OUTPUT -o lo -j ACCEPT

# allow already established
${_IPT} -A INPUT  -m state --state RELATED,ESTABLISHED -j ACCEPT
${_IPT} -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# ICMP (Ping)
${_IPT} -t filter -A OUTPUT -p icmp -j ACCEPT

# rsync (for eix)
${_IPT} -A OUTPUT -p tcp --dport rsync --syn -m state --state NEW -j ACCEPT

# ssh
${_IPT} -A INPUT  -i ${_WINT} -p tcp -m tcp --dport ssh -j ACCEPT
${_IPT} -A OUTPUT -o ${_WINT} -p tcp -m tcp --dport ssh -j ACCEPT

# http, https
${_IPT} -A OUTPUT -o ${_WINT} -p tcp -m tcp --dport http -j ACCEPT
${_IPT} -A OUTPUT -o ${_WINT} -p udp -m udp --dport http -j ACCEPT
${_IPT} -A OUTPUT -o ${_WINT} -p tcp -m tcp --dport https -j ACCEPT

# outgoing ntp
${_IPT} -A OUTPUT -o ${_WINT} -p udp -m udp --dport ntp -j ACCEPT

# dns
${_IPT} -A OUTPUT -p tcp -m tcp --dport domain -j ACCEPT
${_IPT} -A OUTPUT -p udp -m udp --dport domain -j ACCEPT

# OpenVPN
${_IPT} -A OUTPUT -o ${_WINT} -m udp -p udp --dport openvpn -j ACCEPT

# Allow TUN interface connections to OpenVPN server
${_IPT} -A INPUT  -i tun0 -j ACCEPT
${_IPT} -A OUTPUT -o tun0 -j ACCEPT

# Allow TUN interface connections to be forwarded through other interfaces
${_IPT} -A FORWARD -i tun0 -j ACCEPT
${_IPT} -A FORWARD -i tun0 -o ${_WINT} -m state --state RELATED,ESTABLISHED -j ACCEPT
${_IPT} -A FORWARD -i ${_WINT} -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# NAT the VPN client traffic to the internet
${_IPT} -t nat -A POSTROUTING -s 10.2.0.0/24 -o ${_WINT} -j MASQUERADE

# "default reject" instead of "default drop" to make troubleshooting easier
${_IPT} -A INPUT  -j REJECT
${_IPT} -A OUTPUT -j REJECT

# my laptop has no business forwarding packets
${_IPT} -A FORWARD -j REJECT

# I don't use ipv6 and it's buggy and exploitable
${_IP6T} -A FORWARD -j REJECT
${_IP6T} -A INPUT   -j REJECT
${_IP6T} -A OUTPUT  -j REJECT

# usb armory
${_IPT} -t nat -A POSTROUTING -o ${_WINT} -j MASQUERADE

sudo /etc/init.d/iptables save
${_IPT} -L -v --line-numbers
