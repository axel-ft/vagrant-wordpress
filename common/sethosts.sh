#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# sethosts.sh - Adds all the IP addresses of this virtual environment to allow hostname resolution without DNS #
# Usage : ./sethosts.sh current_hostname [current_progress]                                                    #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Add current hostname to the 127.0.0.1 line
sed -i -e "s/.*127.0.0.1.*localhost.*/127.0.0.1\\t${1}\\tlocalhost/" /etc/hosts

# Add one line for each host if it does not already exists (in case of reprovisioning)
grep -qxF "${squid_ip}$(printf '\t')${squid_hostname}"     /etc/hosts || echo -e "${squid_ip}\\t${squid_hostname}"     >> /etc/hosts
# grep -qxF "${haproxy_ip}$(printf '\t')${haproxy_hostname}" /etc/hosts || echo -e "${haproxy_ip}\\t${haproxy_hostname}" >> /etc/hosts
# grep -qxF "${mariadb_ip}$(printf '\t')${mariadb_hostname}" /etc/hosts || echo -e "${mariadb_ip}\\t${mariadb_hostname}" >> /etc/hosts
# for ((i=${glusterfs_ip_start};i<=${glusterfs_ip_end};i++)); do
    # grep -qxF "${range_ip_base}${i}$(printf '\t')${glusterfs_hostname_base}$(printf "%02d" ${i})" /etc/hosts || echo -e "${range_ip_base}${i}\\t${glusterfs_hostname_base}$(printf "%02d" ${i})" >> /etc/hosts
# done
# for ((i=${nginx_ip_start};i<=${nginx_ip_end};i++)); do
    # grep -qxF "${range_ip_base}${i}$(printf '\t')${nginx_hostname_base}$(printf "%02d" ${i})"     /etc/hosts || echo -e "${range_ip_base}${i}\\t${nginx_hostname_base}$(printf "%02d" ${i})"     >> /etc/hosts
# done
# for ((i=${apache_ip_start};i<=${apache_ip_end};i++)); do
    # grep -qxF "${range_ip_base}${i}$(printf '\t')${apache_hostname_base}$(printf "%02d" ${i})"    /etc/hosts || echo -e "${range_ip_base}${i}\\t${apache_hostname_base}$(printf "%02d" ${i})"    >> /etc/hosts
# done
# grep -qxF "${rsyslog_ip}$(printf '\t')${rsyslog_hostname}" /etc/hosts || echo -e "${rsyslog_ip}\\t${rsyslog_hostname}" >> /etc/hosts
# grep -qxF "${elk_ip}$(printf '\t')${elk_hostname}" /etc/hosts || echo -e "${elk_ip}\\t${elk_hostname}" >> /etc/hosts
grep -qxF "${centreon_ip}$(printf '\t')${centreon_hostname}" /etc/hosts || echo -e "${centreon_ip}\\t${centreon_hostname}" >> /etc/hosts


# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0