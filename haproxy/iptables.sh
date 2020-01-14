#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# iptables.sh - HAProxy specific iptables rules applied to the load balancer machine                           #
# Usage : ./iptables.sh protocol [current_progress]                                                            #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# All rules must be set once for IPv4 and once for IPv4 with the dedicated commands iptables et ip6tables

# Select HTTP and HTTPS if protocol is HTTPS, otherwise only select HTTP
if [ ${1} == 'https' ]; then
    inrule='-m multiport --dports http,https'
    outrule='-m multiport --sports http,https'
else
    inrule='--dport http'
    outrule='--sport http'
fi

# Input rules
#IPv4
iptables -A INPUT -i ${guest_interface_name} -p tcp -s ${squid_hostname} --sport 3128 -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Allow Established from proxy
iptables -A INPUT -i ${guest_interface_name} -p tcp --sport 514 -s ${rsyslog_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT  # Established TCP Rsyslog
iptables -A INPUT -i ${guest_interface_name} -p udp --sport 514 -s ${rsyslog_hostname} -m conntrack --ctstate ESTABLISHED -j ACCEPT  # Established UDP Rsyslog
iptables -A INPUT -i ${guest_interface_name} -p tcp $inrule -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                         # Allow new connections to website (HTTP and HTTPS)
iptables -A INPUT -i ${guest_interface_name} -p tcp -m iprange --src-range ${range_ip_base}${nginx_ip_start}-${range_ip_base}${nginx_ip_end} --dport ${1} -m conntrack --ctstate ESTABLISHED -j ACCEPT   # Allow established from nginx web servers
iptables -A INPUT -i ${guest_interface_name} -p tcp -m iprange --src-range ${range_ip_base}${apache_ip_start}-${range_ip_base}${apache_ip_end} --dport ${1} -m conntrack --ctstate ESTABLISHED -j ACCEPT # Allow established from apache web servers
iptables -A INPUT -i ${guest_interface_name} -p tcp -s ${elk_hostname} --sport 5601 -m conntrack --ctstate ESTABLISHED -j ACCEPT # Allow connection to Kibana
iptables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                            # Prevent Internet browsing without proxy
# IPv6
ip6tables -A INPUT -i ${guest_interface_name} -p tcp --dport https -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                  # Allow new connections to website (HTTP and HTTPS)
ip6tables -A INPUT -p tcp -m multiport --sports ftp,http,https -m conntrack --ctstate ESTABLISHED -j DROP                           # Prevent Internet browsing without proxy

# Output rules
# IPv4
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -d ${squid_hostname} --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT   # Allow new connections to the proxy
iptables -A OUTPUT -o ${guest_interface_name} -p tcp --dport 514 -s ${rsyslog_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT  # Allow new TCP Rsyslog
iptables -A OUTPUT -o ${guest_interface_name} -p udp --dport 514 -s ${rsyslog_hostname} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT  # Allow new UDP Rsyslog
iptables -A OUTPUT -o ${guest_interface_name} -p tcp $outrule -m conntrack --ctstate ESTABLISHED -j ACCEPT                                # Allow Established to website
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -m iprange --dst-range ${range_ip_base}${nginx_ip_start}-${range_ip_base}${nginx_ip_end} --dport ${1} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT   # Allow connection to web01 (HTTPS)
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -m iprange --dst-range ${range_ip_base}${apache_ip_start}-${range_ip_base}${apache_ip_end} --dport ${1} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow connection to web02 (HTTPS)
iptables -A OUTPUT -o ${guest_interface_name} -p tcp -d ${elk_hostname} --dport 5601 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow connection to Kibana
iptables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                            # Prevent Internet browsing without proxy
#IPv6
ip6tables -A OUTPUT -o ${guest_interface_name} -p tcp -m multiport --sports http,https -m conntrack --ctstate ESTABLISHED -j ACCEPT       # Allow Established to website
ip6tables -A OUTPUT -p tcp -m multiport --dports ftp,http,https -m conntrack --ctstate NEW,ESTABLISHED -j DROP                           # Prevent Internet browsing without proxy

# Save new custom rules for this machine
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0