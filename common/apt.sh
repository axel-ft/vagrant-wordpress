#!/bin/bash

################################################################################################################
# apt.sh - Does apt-get update, upgrade and installs packages necessary for each virtual machine               #
# Usage : ./apt.sh 'list of packages to install' [current_progress]                                            #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Prevent display of dialog boxes which requires user input
export DEBIAN_FRONTEND=noninteractive

# Updates repositories
apt-get -qq update

# Upgrade system
#apt-get -qq upgrade -y        # Commented to speed up deployments

# Install packages given in arguments
apt-get -qq install -y ${1} --no-install-recommends

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0