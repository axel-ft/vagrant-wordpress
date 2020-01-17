#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - Cockpit configuration operations                                                                 #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Saving SSH host keys to known hosts
ssh-keyscan ${squid_ip} ${haproxy_ip} ${mariadb_ip} >> /etc/ssh/ssh_known_hosts

# Adding machines to dashboard
cat << COCKPIT > /etc/cockpit/machines.d/1-machines.json
{
    "${squid_ip}": {
        "address": "${squid_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
    "${haproxy_ip}": {
        "address": "${haproxy_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
    "${mariadb_ip}": {
        "address": "${mariadb_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
COCKPIT

for ((i=${glusterfs_ip_start};i<=${glusterfs_ip_end};i++)); do
    ssh-keyscan ${range_ip_base}${i} >> /etc/ssh/ssh_known_hosts
    cat << COCKPIT >> /etc/cockpit/machines.d/1-machines.json
    "${range_ip_base}${i}": {
        "address": "${range_ip_base}${i}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
COCKPIT
done

for ((i=${nginx_ip_start};i<=${nginx_ip_end};i++)); do
    ssh-keyscan ${range_ip_base}${i} >> /etc/ssh/ssh_known_hosts
    cat << COCKPIT >> /etc/cockpit/machines.d/1-machines.json
    "${range_ip_base}${i}": {
        "address": "${range_ip_base}${i}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
COCKPIT
done

for ((i=${apache_ip_start};i<=${apache_ip_end};i++)); do
    ssh-keyscan ${range_ip_base}${i} >> /etc/ssh/ssh_known_hosts
    cat << COCKPIT >> /etc/cockpit/machines.d/1-machines.json
    "${range_ip_base}${i}": {
        "address": "${range_ip_base}${i}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
COCKPIT
done

ssh-keyscan ${rsyslog_ip} ${elk_ip} ${centreon_ip} >> /etc/ssh/ssh_known_hosts

cat << COCKPIT >> /etc/cockpit/machines.d/1-machines.json
    "${rsyslog_ip}": {
        "address": "${rsyslog_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
    "${elk_ip}": {
        "address": "${elk_ip}",
        "visible": true,
        "color": "rgb(100, 200, 0)",
        "user": "vagrant"
    },
    "${centreon_ip}": {
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