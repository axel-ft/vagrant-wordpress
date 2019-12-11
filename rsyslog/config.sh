#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - Rsyslog configuration operations                                                                   #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Create dir to receive logs
mkdir -p /srv/rsyslog
chgrp syslog /srv/rsyslog
chmod g+w -R /srv/rsyslog

NAME_LIST="${squid_hostname}, ${haproxy_hostname}, ${mariadb_hostname}, ${rsyslog_hostname}"
for ((i=${glusterfs_ip_start};i<=${glusterfs_ip_end};i++)); do
    NAME_LIST+=", ${glusterfs_hostname_base}${i}"
done
for ((i=${nginx_ip_start};i<=${nginx_ip_end};i++)); do
    NAME_LIST+=", ${nginx_hostname_base}${i}"
done
for ((i=${apache_ip_start};i<=${apache_ip_end};i++)); do
    NAME_LIST+=", ${apache_hostname_base}${i}"
done

# Activate server mode for rsyslog
sed -i.orig -e 's/^#module(load="imudp")$/module(load="imudp")/' \
            -e 's/^#input(type="imudp" port="514")$/input(type="imudp" port="514")/' \
            -e 's/^#module(load="imtcp")$/module(load="imtcp")/' \
            -e 's/^#input(type="imtcp" port="514")$/input(type="imtcp" port="514")/' /etc/rsyslog.conf

# Write Allowed sender variables with all our hosts
grep -qxF "\$AllowedSender UDP, ${NAME_LIST}" /etc/rsyslog.conf || sed -i.bak -e "/input(type=\"imudp\" port=\"514\")/a \
\$AllowedSender UDP, ${NAME_LIST}" /etc/rsyslog.conf
grep -qxF "\$AllowedSender TCP, ${NAME_LIST}" /etc/rsyslog.conf || sed -i -e "/input(type=\"imtcp\" port=\"514\")/a \
\$AllowedSender TCP, ${NAME_LIST}" /etc/rsyslog.conf

# Add template to receive remote logs
grep -qF 'template remote-logs' /etc/rsyslog.conf || sed -i -e "N;/###########################\n#### GLOBAL DIRECTIVES ####/i \
\$PreserveFQDN on\n\n\$template remote-logs,\"/srv/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log\"\n*.* ?remote-logs\n" /etc/rsyslog.conf

# Restarting rsyslog to apply changes, if configuration is correct
rsyslogd -N1 && systemctl restart rsyslog

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0