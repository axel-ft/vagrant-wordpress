#!/bin/bash

################################################################################################################
# addrepo.sh - Add elastic repo to have access to ELK packages                                                 #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Prevent warnings with apt-key reading standard output
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=true

# Get key and add it
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -

# Write repo to source list
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list