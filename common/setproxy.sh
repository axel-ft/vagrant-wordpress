#!/bin/bash

################################################################################################################
# setproxy.sh - Define the proxy to use for HTTP, HTTPS and FTP browsing, system-wide (uses name/IP from args) #
# Usage : ./setproxy.sh proxy_hostname_or_ip [current_progress]                                                #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Define proxy in environment to make changes persistent, only if they are not already present
grep -qxF "ftp_proxy=http://${1}:3128/"   /etc/environment || echo "ftp_proxy=http://${1}:3128/"   >> /etc/environment
grep -qxF "http_proxy=http://${1}:3128/"  /etc/environment || echo "http_proxy=http://${1}:3128/"  >> /etc/environment
grep -qxF "https_proxy=http://${1}:3128/" /etc/environment || echo "https_proxy=http://${1}:3128/" >> /etc/environment

# Define variables for current session
export ftp_proxy=http://${1}:3128/
export http_proxy=http://${1}:3128/
export https_proxy=http://${1}:3128/

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0