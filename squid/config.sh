#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - Squid configuration operations                                                                   #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Getting an array of all the IP addresses
declare -a IP_ADDR
IP_ADDR=( "${squid_ip}" "${mariadb_ip}" "${nginx_ip}" )

# Remove default file
rm /etc/squid/squid.conf

# Writing squid config file
for addr in "${IP_ADDR[@]}"; do
    echo "acl whitelist_ip src ${addr}" >> /etc/squid/squid.conf
done

cat << 'SQUID' >> /etc/squid/squid.conf
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 1025-65535  # unregistered ports
http_access deny !Safe_ports
http_access allow whitelist_ip
http_access allow localhost
http_access allow localhost manager
http_access deny manager
http_access deny all
http_port 0.0.0.0:3128
coredump_dir /var/spool/squid
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\\?) 0     0%      0
refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
refresh_pattern .               0       20%     4320
SQUID

# Restarting Squid to use the new config file if it is correct
squid -k check && systemctl restart squid

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0