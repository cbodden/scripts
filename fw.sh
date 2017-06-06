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

# usb armory
${_IPT} -t nat -A POSTROUTING -o ${_WINT} -j MASQUERADE

# "default reject" instead of "default drop" to make troubleshooting easier
${_IPT} -A INPUT -j REJECT
${_IPT} -A OUTPUT -j REJECT

# my laptop has no business forwarding packets
${_IPT} -A FORWARD -j REJECT

# I don't use ipv6 and it's buggy and exploitable
sudo ip6tables -A FORWARD -j REJECT
sudo ip6tables -A INPUT -j REJECT
sudo ip6tables -A OUTPUT -j REJECT

sudo /etc/init.d/iptables save
${_IPT} -L -v --line-numbers
