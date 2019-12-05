#!/bin/bash

################################################################################################################
# enableservices.sh - Enable and start used services given in args with systemctl                              #
# Usage : ./enableservices.sh 'list of services to enable' [current_progress]                                  #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

for service in "${1}"; do
    systemctl enable --now ${service} 1>/dev/null
done

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0