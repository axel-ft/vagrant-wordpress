#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - Cockpit configuration operations                                                                 #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

cat << COCKPIT > /etc/cockpit/machines.d/1-machines.json
{
    "PROXY - ${squid_hostname}": {
        "address": "${squid_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
    "REVERSE PROXY - ${haproxy_hostname}": {
        "address": "${haproxy_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
    "DB - ${mariadb_hostname}": {
        "address": "${mariadb_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
COCKPIT

for ((i=${glusterfs_ip_start};i<=${glusterfs_ip_end};i++)); do
    cat << COCKPIT > /etc/cockpit/machines.d/1-machines.json
    "FILE - ${glusterfs_hostname_base}$(printf "%02d" ${i})": {
        "address": "${range_ip_base}${i}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
COCKPIT
done

for ((i=${nginx_ip_start};i<=${nginx_ip_end};i++)); do
    cat << COCKPIT > /etc/cockpit/machines.d/1-machines.json
    "WEB (Nginx) - ${nginx_hostname_base}$(printf "%02d" ${i})": {
        "address": "${range_ip_base}${i}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
COCKPIT
done

for ((i=${apache_ip_start};i<=${apache_ip_end};i++)); do
    cat << COCKPIT > /etc/cockpit/machines.d/1-machines.json
    "WEB (Apache) - ${apache_hostname_base}$(printf "%02d" ${i})": {
        "address": "${range_ip_base}${i}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
COCKPIT
done

cat << COCKPIT > /etc/cockpit/machines.d/1-machines.json
    "LOG - ${rsyslog_hostname}": {
        "address": "${rsyslog_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
    "LOG - ${elk_hostname}": {
        "address": "${elk_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
    "MONITORING - ${centreon_hostname}": {
        "address": "${centreon_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    }
}
COCKPIT

systemctl restart cockpit

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0