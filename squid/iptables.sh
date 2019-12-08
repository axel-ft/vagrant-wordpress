#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# iptables.sh - Squid specific iptables rules applied to the proxy machine                                     #
# Usage : ./iptables.sh [current_progress]                                                                     #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# All rules must be set once for IPv4 and once for IPv4 with the dedicated commands iptables et ip6tables

# Input rules
# IPv4
iptables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j ACCEPT                              # Established FTP,HTTP,HTTPS
iptables -A INPUT -i ${bridgeif_guest_name} -p tcp --dport 3128 -s ${squid_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT   # Proxy authorized hosts
iptables -A INPUT -i ${bridgeif_guest_name} -p tcp --dport 3128 -s ${mariadb_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Proxy authorized hosts
iptables -A INPUT -i ${bridgeif_guest_name} -p tcp --dport 3128 -s ${nginx_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT   # Proxy authorized hosts
# IPv6
ip6tables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j ACCEPT # Established FTP,HTTP,HTTPS

# Output rules
# IPv4
iptables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                      # Allow trafic to http, https, and ftp
iptables -A OUTPUT -o ${bridgeif_guest_name} -p tcp --sport 3128 -d ${squid_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Proxy authorized hosts
iptables -A OUTPUT -o ${bridgeif_guest_name} -p tcp --sport 3128 -d ${mariadb_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT # Proxy authorized hosts
iptables -A OUTPUT -o ${bridgeif_guest_name} -p tcp --sport 3128 -d ${nginx_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Proxy authorized hosts
# IPv6
ip6tables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow trafic to http, https, and ftp

# Change common default policies
ip6tables -P OUTPUT ACCEPT # Accept by default (troubles with drop policy, particularly with squid port binding)

# Save new custom rules for this machine
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0