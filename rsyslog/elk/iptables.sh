#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# /!\ This is meant to be used with the rsyslog machine and does not contain the rules for a separate machine  #
# iptables.sh - ELK specific iptables rules applied to the Elastic Logstash Kibana stack                       #
# Usage : ./iptables.sh [current_progress]                                                                     #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# All rules must be set once for IPv4 and once for IPv4 with the dedicated commands iptables et ip6tables

# Input rules
#IPv4
iptables -A INPUT -i ${bridgeif_guest_name} -p tcp -s ${haproxy_hostname} --dport 5601 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT         # Allow New connections to kibana only from load balancer
iptables -A INPUT -p tcp -s ${rsyslog_hostname} -d ${rsyslog_hostname} --dport 5601 -m conntrack --ctstate ESTABLISHED -j ACCEPT  # Loopback rule to access kibana locally without proxy

# Output rules
# IPv4
iptables -A OUTPUT -o ${bridgeif_guest_name} -p tcp -d ${haproxy_hostname} --sport 5601 -m conntrack --ctstate ESTABLISHED -j ACCEPT                 # Allow Established connections from kibana to load balancer only
iptables -A OUTPUT -p tcp -s ${rsyslog_hostname} -d ${rsyslog_hostname} --dport 5601 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT  # Loopback rule to access kibana locally without proxy

# Save new custom rules for this machine
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0