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

_WINT=wlp3s0
_IPT="sudo /sbin/iptables"
_IP6T="sudo /sbin/ip6tables"

echo 1 \
    | sudo tee /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

for ITER in /proc/sys/net/ipv4/conf/*/accept_source_route
do
    echo 0 \
        | sudo tee ${ITER}
done

for ITER in /proc/sys/net/ipv4/conf/*/accept_redirects
do
    echo 0 \
        | sudo tee ${ITER}
done

for ITER in /proc/sys/net/ipv4/conf/*/rp_filter
do
    echo 1 \
        | sudo tee ${ITER}
done

echo 1 \
    | sudo tee /proc/sys/net/ipv4/tcp_syncookies

# clear iptables
${_IPT} -F

# allow anything on localhost
${_IPT} -A INPUT -i lo -j ACCEPT
${_IPT} -A OUTPUT -o lo -j ACCEPT

# allow already established
${_IPT} -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
${_IPT} -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# ICMP (Ping)
${_IPT} -t filter -A OUTPUT -p icmp -j ACCEPT

# rsync (for eix)
${_IPT} -A OUTPUT -p tcp --dport rsync --syn -m state --state NEW -j ACCEPT

# ssh
${_IPT} -A INPUT -i ${_WINT} -p tcp -m tcp --dport 22 -j ACCEPT
${_IPT} -A OUTPUT -o ${_WINT} -p tcp -m tcp --dport 22 -j ACCEPT

# http, https
${_IPT} -A OUTPUT -o ${_WINT} -p tcp -m tcp --dport 80 -j ACCEPT
${_IPT} -A OUTPUT -o ${_WINT} -p udp -m udp --dport 80 -j ACCEPT
${_IPT} -A OUTPUT -o ${_WINT} -p tcp -m tcp --dport 443 -j ACCEPT

# outgoing ntp
${_IPT} -A OUTPUT -o ${_WINT} -p udp -m udp --dport 123 -j ACCEPT

# dns
${_IPT} -A OUTPUT -p tcp -m tcp --dport 53 -j ACCEPT
${_IPT} -A OUTPUT -p udp -m udp --dport 53 -j ACCEPT


##### testing begin - connects but does not route #####
### OpenVPN
##sudo iptables -A OUTPUT -o ${_WINT} -m udp -p udp --dport 1194 -j ACCEPT
##
### Allow TUN interface connections to OpenVPN server
##sudo iptables -A INPUT -i tun0 -j ACCEPT
##
### Allow TUN interface connections to be forwarded through other interfaces
##sudo iptables -A FORWARD -i tun0 -j ACCEPT
##sudo iptables -A FORWARD -i tun0 -o ${_WINT} -m state --state RELATED,ESTABLISHED -j ACCEPT
##sudo iptables -A FORWARD -i ${_WINT} -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
##### testing end #####


# "default reject" instead of "default drop" to make troubleshooting easier
${_IPT} -A INPUT -j REJECT
${_IPT} -A OUTPUT -j REJECT

# my laptop has no business forwarding packets
${_IPT} -A FORWARD -j REJECT

# I don't use ipv6 and it's buggy and exploitable
${_IP6T} -A FORWARD -j REJECT
${_IP6T} -A INPUT -j REJECT
${_IP6T} -A OUTPUT -j REJECT

# usb armory
${_IPT} -t nat -A POSTROUTING -o ${_WINT} -j MASQUERADE

# NAT the VPN client traffic to the internet
${_IPT} -A OUTPUT -o tun0 -j ACCEPT

sudo /etc/init.d/iptables save
${_IPT} -L -v --line-numbers
