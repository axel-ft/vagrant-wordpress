#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# iptables.sh - Nginx specific iptables rules applied to the nginx machines                                    #
# Usage : ./iptables.sh protocol [current_progress]                                            #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# All rules must be set once for IPv4 and once for IPv4 with the dedicated commands iptables et ip6tables

# Input rules
#IPv4
iptables -A INPUT -i ${bridgeif_guest_name} -p tcp -s ${mariadb_hostname} --sport mysql -m conntrack --ctstate ESTABLISHED -j ACCEPT    # Allow Established connections to database
iptables -A INPUT -i ${bridgeif_guest_name} -p tcp -s ${squid_hostname} --sport 3128 -m conntrack --ctstate ESTABLISHED -j ACCEPT       # Allow Established from proxy
iptables -A INPUT -i ${bridgeif_guest_name} -p tcp --dport ${1} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                        # Allow New connections to website only from load balancer
iptables -A INPUT -p tcp -s ${nginx_hostname} -d ${nginx_hostname} --dport ${1} -m conntrack --ctstate ESTABLISHED -j ACCEPT            # Loopback rule to access website locally without proxy
iptables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                                # Prevent Internet browsing without proxy
# IPv6
ip6tables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                               # Prevent Internet browsing without proxy

# Output rules
# IPv4
iptables -A OUTPUT -o ${bridgeif_guest_name} -p tcp -d ${mariadb_hostname} --dport mysql -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow new connections to the database
iptables -A OUTPUT -o ${bridgeif_guest_name} -p tcp -d ${squid_hostname} --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT    # Allow new connections to the proxy
iptables -A OUTPUT -o ${bridgeif_guest_name} -p tcp --sport ${1} -m conntrack --ctstate ESTABLISHED -j ACCEPT                             # Allow Established connections from website to load balancer only
iptables -A OUTPUT -p tcp -s ${nginx_hostname} -d ${nginx_hostname} --dport ${1} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT         # Loopback rule to access website locally without proxy
iptables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                             # Prevent Internet browsing without proxy
# IPv6
ip6tables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                            # Prevent Internet browsing without proxy

# Save new custom rules for this machine
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0