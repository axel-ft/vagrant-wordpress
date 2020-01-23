#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# iptables.sh - ELK specific iptables rules applied to the Elastic Logstash Kibana stack                       #
# Usage : ./iptables.sh [current_progress]                                                                     #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# All rules must be set once for IPv4 and once for IPv4 with the dedicated commands iptables et ip6tables

# Input rules
# IPv4
iptables -A INPUT -i ${guest_interface_name} -p tcp -s ${squid_hostname} --sport 3128 -m conntrack --ctstate ESTABLISHED -j ACCEPT       # Allow Established from proxy
iptables -A INPUT -i ${guest_interface_name} -p tcp -s ${haproxy_hostname} --dport 5601 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow New connections to kibana only from load balancer
iptables -A INPUT -i ${guest_interface_name} -p tcp -s ${rsyslog_hostname} --dport 5044 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow New connections to logstash only from rsyslog machine
iptables -A INPUT -i ${guest_interface_name} -p tcp -s ${rsyslog_hostname} --dport 9200 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow New connections to elasticsearch only from rsyslog machine
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 22 -s ${cockpit_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -s ${elk_hostname} -d ${elk_hostname} --dport 5601 -m conntrack --ctstate ESTABLISHED -j ACCEPT                # Loopback rule to access kibana locally without proxy
iptables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                                # Prevent Internet browsing without proxy
# IPv6
ip6tables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                     # Prevent Internet browsing without proxy

# Output rules
# IPv4
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -d ${squid_hostname} --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow new connections to the proxy
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -d ${haproxy_hostname} --sport 5601 -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Allow Established connections from kibana to load balancer only
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -d ${rsyslog_hostname} --sport 5044 -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Allow Established connections to logstash only from rsyslog machine
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -d ${rsyslog_hostname} --sport 9200 -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Allow Established connections to elasticsearch only from rsyslog machine
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 22 -s ${cockpit_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -s ${elk_hostname} -d ${elk_hostname} --dport 5601 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT          # Loopback rule to access kibana locally without proxy
iptables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                          # Prevent Internet browsing without proxy
# IPv6
ip6tables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                     # Prevent Internet browsing without proxy

# Save new custom rules for this machine
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0