#!/bin/bash

################################################################################################################
# addrepo.sh - Add nodesource repo to have access to NodeJS packages                                           #
# Usage : ./addrepo.sh [current_progress]                                                                      #
# Author: Charly Estay, Matthieu Poulier                                                                       #
################################################################################################################

# Prevent warnings with apt-key reading standard output
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=true

# Get key and add it
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -