#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# iptables.sh - Rsyslog specific iptables rules applied to the log machine                                     #
# Usage : ./iptables.sh [current_progress]                                                                     #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# All rules must be set once for IPv4 and once for IPv4 with the dedicated commands iptables et ip6tables

# Input rules
# IPv4
iptables -A INPUT -i ${guest_interface_name} -p tcp -s ${squid_hostname} --sport 3128 -m conntrack --ctstate ESTABLISHED -j ACCEPT      # Allow Established from proxy
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 514 -s ${squid_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT   # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 514 -s ${haproxy_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 514 -s ${mariadb_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 514 -m iprange --src-range ${range_ip_base}${glusterfs_ip_start}-${range_ip_base}${glusterfs_ip_end} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT  # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 514 -m iprange --src-range ${range_ip_base}${nginx_ip_start}-${range_ip_base}${nginx_ip_end} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT          # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 514 -m iprange --src-range ${range_ip_base}${apache_ip_start}-${range_ip_base}${apache_ip_end} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT        # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 514 -s ${centreon_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT     # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p tcp --dport 514 -s ${elk_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT     # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 514 -s ${squid_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT   # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 514 -s ${haproxy_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 514 -s ${mariadb_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 514 -m iprange --src-range ${range_ip_base}${glusterfs_ip_start}-${range_ip_base}${glusterfs_ip_end} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT  # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 514 -m iprange --src-range ${range_ip_base}${nginx_ip_start}-${range_ip_base}${nginx_ip_end} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT          # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 514 -m iprange --src-range ${range_ip_base}${apache_ip_start}-${range_ip_base}${apache_ip_end} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT        # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 514 -s ${elk_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT     # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p udp --dport 514 -s ${centreon_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT     # Rsyslog authorized hosts
iptables -A INPUT -i ${guest_interface_name} -p tcp --sport 5044 -s ${elk_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT        # Filebeat output to logstash
iptables -A INPUT -i ${guest_interface_name} -p tcp --sport 9200 -s ${elk_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT        # Filebeat output to Elasticsearch
iptables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                      # Prevent Internet browsing without proxy
# IPv6
ip6tables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                     # Prevent Internet browsing without proxy

# Output rules
# IPv4
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -d ${squid_hostname} --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow new connections to the proxy
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 514 -d ${squid_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT      # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 514 -d ${haproxy_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT    # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 514 -d ${mariadb_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT    # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 514 -m iprange --dst-range ${range_ip_base}${glusterfs_ip_start}-${range_ip_base}${glusterfs_ip_end} -m conntrack --ctstate ESTABLISHED -j ACCEPT # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 514 -m iprange --dst-range ${range_ip_base}${nginx_ip_start}-${range_ip_base}${nginx_ip_end} -m conntrack --ctstate ESTABLISHED -j ACCEPT         # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 514 -m iprange --dst-range ${range_ip_base}${apache_ip_start}-${range_ip_base}${apache_ip_end} -m conntrack --ctstate ESTABLISHED -j ACCEPT       # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 514 -d ${centreon_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT        # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --sport 514 -d ${elk_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT        # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 514 -d ${squid_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT      # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 514 -d ${haproxy_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT    # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 514 -d ${mariadb_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT    # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 514 -m iprange --dst-range ${range_ip_base}${glusterfs_ip_start}-${range_ip_base}${glusterfs_ip_end} -m conntrack --ctstate ESTABLISHED -j ACCEPT # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 514 -m iprange --dst-range ${range_ip_base}${nginx_ip_start}-${range_ip_base}${nginx_ip_end} -m conntrack --ctstate ESTABLISHED -j ACCEPT         # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 514 -m iprange --dst-range ${range_ip_base}${apache_ip_start}-${range_ip_base}${apache_ip_end} -m conntrack --ctstate ESTABLISHED -j ACCEPT       # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 514 -d ${elk_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT        # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p udp --sport 514 -d ${centreon_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT        # Rsyslog authorized hosts
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --dport 5044 -d ${elk_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT   # Filebeat output to logstash
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --dport 9200 -d ${elk_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT   # Filebeat output to Elasticsearch
iptables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                      # Prevent Internet browsing without proxy
# IPv6
ip6tables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                     # Prevent Internet browsing without proxy

# Save new custom rules for this machine
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0