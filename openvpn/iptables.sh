#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# iptables.sh - Cockpit specific iptables rules applied to the proxy machine                                   #
# Usage : ./iptables.sh [current_progress]                                                                     #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# All rules must be set once for IPv4 and once for IPv4 with the dedicated commands iptables et ip6tables

# Input rules
# IPv4
iptables -A INPUT -i ${guest_interface_name} -p tcp -s ${squid_hostname} --sport 3128  -m conntrack --ctstate ESTABLISHED -j ACCEPT               # Allow Established connections to the proxy
iptables -A INPUT -i ${guest_interface_name} -p tcp --sport 514 -s ${rsyslog_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT               # Established TCP Rsyslog
iptables -A INPUT -i ${guest_interface_name} -p udp --sport 514 -s ${rsyslog_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT               # Established UDP Rsyslog
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 1194 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT          # OpenVPN
iptables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                                         # Prevent Internet browsing without proxy
# IPv6
ip6tables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                                        # Prevent Internet browsing without proxy

# Output rules
# IPv4
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --dport 514 -s ${rsyslog_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT               # Allow new TCP Rsyslog
iptables -A OUTPUT -o ${guest_interface_name} -p udp --dport 514 -s ${rsyslog_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT               # Allow new UDP Rsyslog
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -d ${squid_hostname} --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                # Allow new connections to the proxy
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 1194 -m conntrack --ctstate ESTABLISHED -j ACCEPT          # OpenVPN
iptables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                                         # Prevent Internet browsing without proxy
# IPv6
ip6tables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                                        # Prevent Internet browsing without proxy

# Save new custom rules for this machine
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${3} ] && progressbar ${3}
exit 0