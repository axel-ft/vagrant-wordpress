#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# rsyslog.sh - Rsyslog client configuration operations                                                         #
# Usage : ./setrsyslog.sh log_server [current_progress]                                                        #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

mv /etc/rsyslog.d/50-default.conf /etc/rsyslog.d/50-default.conf.bak

cat << RSYSLOG > /etc/rsyslog.d/50-default.conf
\$PreserveFQDN                  on
\$ActionQueueFileName           queue
\$ActionQueueMaxDiskSpace       1g
\$ActionQueueSaveOnShutdown     on
\$ActionQueueType               LinkedList
\$ActionResumeRetryCount        -1

*.*                             @@${rsyslog_hostname}:514

auth,authpriv.*                 /var/log/auth.log
*.*;auth,authpriv.none          -/var/log/syslog
kern.*                          -/var/log/kern.log
mail.*                          -/var/log/mail.log
mail.err                        /var/log/mail.err
*.emerg                         :omusrmsg:*
RSYSLOG

# Restarting rsyslog to apply changes, if configuration is correct
rsyslogd -N1 && systemctl restart rsyslog

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0